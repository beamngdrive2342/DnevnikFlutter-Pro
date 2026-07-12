# Фаза 4 — Официальный Firebase SDK + Storage + серверные удаления

**Роль:** опытный Flutter-разработчик. Проект `dnevnik_app`. Рабочая директория `src/`.
**Предусловие:** Фазы 1–3 закрыты (тесты, Riverpod-состояние, разрезанные экраны).

**Цель фазы:** заменить ручной Firestore REST на официальный Firebase SDK, перенести картинки
из тела документов в Firebase Storage, а массовые удаления — на сервер (Cloud Function).
Это самая крупная и рискованная фаза; она **опциональна** и может делаться по частям.

**Риск:** высокий. Меняется способ доступа к данным и модель хранения. Обязательна страховка
тестами (фаза 1) и ручной прогон всех потоков. Рекомендуется делать в отдельной ветке и,
по возможности, сохранить обратную совместимость чтения старых данных.

> ⚠️ Перед стартом: этой фазе нужны реальные учётные данные Firebase-проекта `domashka-381cb`
> (google-services.json / GoogleService-Info.plist, доступ в консоль). Если их нет — НЕ начинать,
> записать блокер в `NOTES.md`. Также решить с владельцем: делаем миграцию данных или только
> новые данные идут по-новому.

---

## Definition of Done

1. Чтение/запись домашки и классов идёт через `cloud_firestore`, аутентификация — через
   `firebase_auth`. Ручная сериализация `{'stringValue': ...}` и самодельный REST удалены
   (или изолированы только под миграцию legacy-данных).
2. Домашка обновляется реактивно через `snapshots()` (real-time), самодельный дисковый кэш
   заменён/упрощён за счёт встроенной offline-персистенции Firestore.
3. Картинки хранятся в Firebase Storage; в документах — только ссылки. Инлайновый base64 и
   `_migrateHostedImagesToEmbedded` удалены (при необходимости — одноразовая обратная миграция).
4. Массовое удаление (класс + подколлекции homework/members) выполняется Cloud Function,
   а не циклом на клиенте.
5. `flutter analyze` чистый, `flutter test` зелёный, все ручные потоки работают.

---

## Порядок (можно останавливаться после любого блока — каждый самоценен)

### Блок A. Подключить Firebase SDK
- Добавить зависимости: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`.
- `flutterfire configure` (или ручная настройка `firebase_options.dart`, google-services.json,
  GoogleService-Info.plist) для android/ios/web.
- В `main.dart`: `await Firebase.initializeApp(...)` до `runApp`.
- Включить offline-персистенцию Firestore (по умолчанию на mobile включена; на web — настроить).
- Коммит: `feat(firebase): подключить Firebase Core/Auth/Firestore/Storage`.

### Блок B. Auth через firebase_auth
- Переписать `authServiceProvider`:
  - админ: `createUserWithEmailAndPassword` / `signInWithEmailAndPassword`;
  - ученик: `signInAnonymously`;
  - сессия/токен: управляется SDK (`authStateChanges()`), убрать ручной refresh-token flow
    и `flutter_secure_storage` для токена (SDK хранит сам). `restoreSession()` заменяется на
    подписку `authStateChanges()`.
- Провайдер `authProvider` слушает `authStateChanges()` вместо ручной проверки SharedPreferences.
- Сохранить `classId`/роль (это доменные данные) — можно в Firestore-документе пользователя или
  как есть в prefs, но токен/refresh — только через SDK.
- Коммит: `refactor(auth): firebase_auth вместо ручного Identity Toolkit REST`.

### Блок C. Firestore через cloud_firestore
- Заменить `homeworkProvider`/`scheduleProvider` на чтение через `FirebaseFirestore.instance`:
  - домашка: `collection('classes/{classId}/homework').snapshots()` → стрим в `AsyncNotifier`
    (реактивно, без ручного TTL/диска).
  - класс/расписание: `doc('classes/{classId}').snapshots()`.
- Модели: заменить ручные `_toFirestore/_fromFirestore` на `withConverter<HomeworkItem>()`
  + `fromJson/toJson` (у `HomeworkItem` уже есть `fromJson/toJson`; сверить формат полей).
- Запросы вроде «найти класс по adminEmail» — через `where('adminEmail', isEqualTo: ...)`.
- Обеспечить чтение legacy-документов (старый формат совпадает — Firestore тот же), проверить
  поля `imageUrls/fullResolutionUrls/textbookNumbers`.
- Коммит: `refactor(data): cloud_firestore вместо ручного REST`.

### Блок D. Картинки в Storage
- При добавлении ДЗ фото грузить в `FirebaseStorage` (`ref('classes/{classId}/hw/{id}/{n}.jpg')`),
  в документ писать download URL (и опционально путь для удаления).
- Отображение — существующий `NetworkPhoto`/`cached_network_image` по URL (уже используется).
- Удалить инлайновый base64: `image_data.dart` (`encodeInlineImageData`/`isInlineImageData`),
  `_migrateHostedImagesToEmbedded`, `_triggerHostedImageMigration`.
- Если в проде остались документы с base64 — сделать одноразовый скрипт/функцию обратной
  миграции base64 → Storage, затем удалить legacy-поля.
- Коммит: `feat(storage): фото ДЗ в Firebase Storage, ссылки в документах`.

### Блок E. Серверные удаления (Cloud Function)
- Реализовать Callable Cloud Function `deleteClass(classId)` (Node/TS в `functions/`), которая
  рекурсивно удаляет `classes/{id}` + подколлекции `homework`/`members` + `class_codes/{code}`
  + Storage-объекты класса + (для админа) Firebase Auth аккаунт через Admin SDK.
- Клиент вызывает функцию через `cloud_functions` вместо циклов
  `_deleteHomeworkSubcollection`/`_deleteMembersSubcollection`. Удалить эти клиентские циклы.
- Обновить/проверить **Firestore Security Rules** и Storage Rules: ученик не может писать в чужой
  класс, только админ класса меняет расписание/удаляет. (Security Rules были дырой при ручном REST —
  зафиксировать их состояние в `NOTES.md`.)
- Коммит: `feat(functions): серверное каскадное удаление класса/аккаунта`.

---

## Ограничения scope
- Не менять UI/UX и внешний вид.
- Не смешивать с рефактором структуры (фаза 3 уже сделана).
- Каждый блок (A–E) — отдельный коммит и отдельная верификация; допустимо завершить фазу
  после любого блока, оставив остальные в `NOTES.md` как следующий этап.

---

## Верификация

```bash
cd src
flutter pub get
flutter analyze
flutter test
```
Ручные сценарии (реальный `flutter run` на устройстве/эмуляторе):
1. Регистрация админа → создание класса → выход → вход админом (сессия восстановилась через SDK).
2. Вступление ученика по коду (анонимный вход) → видит расписание и домашку.
3. Админ добавляет ДЗ с фото → у ученика оно появляется **в реальном времени** (snapshots).
4. Оффлайн-режим: выключить сеть → домашка всё ещё видна (offline-персистенция Firestore).
5. Удаление класса/аккаунта → данные и Storage-объекты вычищены (проверить в консоли Firebase).
6. Открыть старое (legacy) ДЗ, созданное до миграции — оно корректно читается/показывается.

Показать: список удалённого самодельного кода (REST/сериализация/inline-base64/циклы удаления),
новые зависимости, статус Rules, вывод analyze/test.
