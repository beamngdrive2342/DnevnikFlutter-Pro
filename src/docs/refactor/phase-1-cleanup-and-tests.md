# Фаза 1 — Уборка и тесты-страховка

**Роль:** ты опытный Flutter/Dart-разработчик. Работаешь в проекте `dnevnik_app`
(школьный дневник: расписание + домашка, Firestore через REST, ИИ через Vercel-прокси).
Рабочая директория — `src/`.

**Цель фазы:** убрать мусор и мёртвый код, устранить дублирование форматирования дат и
поставить настоящие unit-тесты на чистую логику. После этой фазы у проекта появляется
работающая страховка `flutter test`, на которую опираются все следующие фазы.

**Риск:** низкий. Мы почти не трогаем поведение приложения — чистим и добавляем тесты.

---

## Definition of Done (что считается «фаза закрыта»)

1. Фейковые «тесты»-скрипты удалены, вместо них — настоящие unit-тесты.
2. Мёртвый код из `diary_screen.dart` удалён.
3. Форматирование даты `YYYY-MM-DD` идёт только через `formatDateIso()` (нет ручных дублей).
4. `flutter analyze` — без новых warnings/errors (в идеале 0).
5. `flutter test` — зелёный, и в нём **минимум 12 осмысленных проверок** (не пустышки).
6. `widget_test.dart` починен и проходит (сейчас он, скорее всего, падает).

---

## Карта файлов, которые трогаем

- `test/test_ai.dart`, `test/test_firestore.dart` — УДАЛИТЬ (это не тесты, а сетевые скрипты с `main()`; в первом лежит мёртвый Google-ключ).
- `test/widget_test.dart` — починить.
- `lib/screens/diary_screen.dart` — удалить мёртвый код.
- `lib/utils/app_date_utils.dart` — источник правды по датам (уже содержит `formatDateIso`).
- `lib/data/firestore_service.dart`, `lib/data/ai_service.dart` — заменить ручное форматирование даты на `formatDateIso`.
- `lib/data/ai_service.dart` — `_extractQuickHomeworkJson` сделать тестируемым.
- Новые файлы тестов в `test/`.

---

## Шаги

### Шаг 1. Удалить фейковые тесты
- Удалить `test/test_ai.dart` и `test/test_firestore.dart`.
- Обоснование: в них нет `test()`/`expect()`, они бьют в реальную сеть, а `test_ai.dart`
  содержит захардкоженный (уже нерабочий) Google API-ключ — незачем держать его в истории.
- Коммит: `test: удалить фейковые сетевые скрипты из test/`.

### Шаг 2. Удалить мёртвый код в diary_screen
- В `lib/screens/diary_screen.dart` удалить метод `_showLessonDetails(...)` целиком
  (помечен `// ignore: unused_element`, ~300 строк) вместе с большим закомментированным
  блоком внутри него (сохранение фото).
- Убедиться, что `_showLessonDetails` нигде не вызывается (grep по проекту). Если внезапно
  вызывается — НЕ удалять, записать в `NOTES.md` и пропустить шаг.
- После удаления проверить, что не осталось «повисших» приватных методов, которые
  использовались только оттуда. Неиспользуемые — тоже удалить (ориентир — `flutter analyze`).
- Коммит: `refactor(diary): удалить мёртвый _showLessonDetails и закомментированный код`.

### Шаг 3. Централизовать форматирование даты
- Найти все ручные конструкции вида
  `'${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}'`
  (встречается в `diary_screen.dart`, `firestore_service.dart`, `ai_service.dart`).
- Заменить их на `formatDateIso(date)` из `lib/utils/app_date_utils.dart` (добавить импорт).
- В `firestore_service.dart` метод `_parseHomeworkDate` дублирует логику `parseHomeworkDeadline`
  из `app_date_utils.dart` — заменить использование на общую функцию, приватную удалить.
- Поведение не меняем — только источник. Коммит: `refactor: единый formatDateIso/parseHomeworkDeadline`.

### Шаг 4. Сделать чистую логику тестируемой
- `AIService._extractQuickHomeworkJson` — приватный статик. Пометить его
  `@visibleForTesting` и переименовать в `extractQuickHomeworkJson` (публичный для тестов),
  либо добавить тонкую `@visibleForTesting` обёртку. Импортировать `package:meta/meta.dart`
  или `package:flutter/foundation.dart` для аннотации.
- Аналогично обеспечить тестовый доступ к:
  - `FirestoreService` парсингу документа (`_fromFirestore`) — вынести в top-level функцию
    `homeworkItemFromFirestore(Map)` в том же файле или пометить `@visibleForTesting`.
  - логике «просрочено» — вынести чистую функцию `bool isHomeworkExpired(String deadline, {DateTime? now})`.
  - `ClassSchedule.loadFromFirestoreDoc` — она уже публичная и статическая, тестируется как есть
    (после вызова проверяем `ClassSchedule.subjects`, `weekSchedule`, не забыть `ClassSchedule.reset()` в tearDown).
- Не менять поведение — только видимость/выделение чистых функций.

### Шаг 5. Написать unit-тесты
Создать файлы:
- `test/ai_service_test.dart` — на `extractQuickHomeworkJson`:
  - чистый JSON;
  - JSON внутри ```json ...``` fenced-блока;
  - JSON с мусорным текстом до/после;
  - совсем не-JSON → должен вернуть `fallback: true` и null-поля.
- `test/firestore_parsing_test.dart` — на парсинг Firestore-документа:
  - документ с `imageUrls`/`fullResolutionUrls`/`textbookNumbers`;
  - документ без `id` (id берётся из `name`);
  - пустой/битый документ не роняет парсер.
- `test/homework_expiry_test.dart` — на `isHomeworkExpired`:
  - дедлайн старше 14 дней → true;
  - сегодняшний → false;
  - будущий → false;
  - невалидная дата → false.
- `test/schedule_data_test.dart` — на `ClassSchedule.loadFromFirestoreDoc`:
  - валидный doc заполняет subjects/lessonTimes/weekSchedule;
  - `reset()` возвращает к дефолтам (`isLoaded == false`).
  - Обязательно `setUp`/`tearDown` с `ClassSchedule.reset()` — статика течёт между тестами!
- `test/date_utils_test.dart` — `formatDateIso`, `parseHomeworkDeadline` (валид/невалид/пусто).

Требование: не меньше **12** реальных `expect`. Тесты не должны ходить в сеть.

### Шаг 6. Починить widget_test.dart
- Текущий `pumpWidget(const DnevnikApp())` почти наверняка падает: `DnevnikApp` — `ConsumerWidget`
  и требует `ProviderScope` сверху; плюс `main()` грузит `.env` через `dotenv`, а тест — нет.
- Починить:
  - обернуть в `ProviderScope(child: DnevnikApp())`;
  - перед `pumpWidget` инициализировать dotenv тестовым значением:
    `dotenv.testLoad(fileInput: 'FIREBASE_WEB_API_KEY=test');` (импорт `flutter_dotenv`);
  - если проверка на `AuthGate` флейки из-за асинхронного `_checkSession` — заменить на более
    стабильную (например, `expect(find.byType(MaterialApp), findsOneWidget)` после `pump()`),
    не полагаться на сетевые вызовы.
- Тест должен стать детерминированным и зелёным.

---

## Ограничения scope (НЕ делать в этой фазе)
- Не переводить состояние на Riverpod (это фаза 2).
- Не резать большие экраны (фаза 3).
- Не менять сетевые контракты/формат Firestore.
- Не менять UI визуально.

---

## Верификация (обязательно выполнить и показать вывод)

```bash
cd src
flutter analyze
flutter test
```

- `flutter analyze`: 0 новых ошибок. Если остались старые — зафиксировать их число до/после.
- `flutter test`: всё зелёное, показать количество пройденных тестов.
- Ручной прогон (любой из доступных):
  ```bash
  flutter run -d chrome   # или -d <android/ios устройство>
  ```
  Проверить сценарий: приложение стартует → экран дневника открывается → календарь
  скроллится → карточки уроков видны. Убедиться, что удаление мёртвого кода ничего не сломало
  в экране дневника (открытие фото по тапу всё ещё работает через `_openFullScreenImage`).

## Итог фазы
Короткий отчёт: что удалено, сколько тестов добавлено, число проходящих тестов,
статус `flutter analyze`. Обновить галочку Фазы 1 в `docs/refactor/README.md` при желании.
