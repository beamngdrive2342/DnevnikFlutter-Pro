# Архитектурные решения — DnevnikFlutter

## 📋 Формат

```
## YYYY-MM-DD - [Название решения]
- **Status:** proposed | accepted | rejected | replaced
- **Decision:** [Что решили делать]
- **Why:** [Почему этот вариант лучше]
- **Consequences:** [Что становится проще/сложнее]
- **Rollback:** [Как откатиться если понадобится]
```

---

## 2026-06-25 - Отказ от Firebase Cloud Messaging (на данный момент)
- **Status:** rejected (reverted)
- **Decision:** Отменить все изменения, связанные с внедрением push-уведомлений (FCM) и использованием `firebase-admin` на Vercel.
- **Why:** Интеграция потребовала усложнения Vercel-прокси (смешивание Edge Runtime и Node.js), что привело к конфликтам модулей (ESM vs CommonJS). Пользователь решил отменить изменения, чтобы сохранить текущую архитектуру чистой и стабильной.
- **Consequences:** Push-уведомления пока не работают. Код возвращен к состоянию до 2026-06-25.

## 2026-06-25 - Отказ от автоматической генерации SVG для чертежей ГДЗ
- **Status:** rejected
- **Decision:** Не использовать сырой векторный SVG-код для замены картинок из решебников (в целях обхода авторских прав).
- **Why:** ИИ-генерация или ручное написание "сырого" SVG кода для сложных геометрических задач (с перспективой, эллипсами и точным попаданием линий в нужные координаты) слишком трудозатратна, часто неточна и хрупка. Альтернативные варианты (встраивание GeoGebra, готовые нарисованные в сторонних редакторах PNG/SVG) намного надежнее и проще в масштабировании.
- **Consequences:** Удалены `flutter_svg`, `flutter_markdown` и логика просмотра Markdown-решений. Возвращаемся к показу обычных картинок. В будущем для собственных решений будут использоваться готовые картинки или скрипты математических движков.
- **Rollback:** -

## 2026-06-24 - Хранение готовых ответов (ГДЗ) на GitHub (Raw CDN)
- **Status:** accepted
- **Decision:** Вынести 3400+ фотографий с решениями (Геометрия, Алгебра) из локальных `assets/` в публичный репозиторий GitHub и загружать их через `raw.githubusercontent.com`.
- **Why:** Изначально картинки были добавлены в `assets/`, что раздуло размер APK с 100 МБ до 400+ МБ, сделав его непригодным для дистрибуции. S3/Firebase Storage стоит денег, а GitHub Pages/Raw — бесплатно.
- **Consequences:** Для просмотра ответов в первый раз потребуется интернет. APK вернулся к нормальным 111 МБ.
- **Rollback:** Загрузить картинки обратно в `assets/` и прописать их в `pubspec.yaml`, либо использовать платный S3 Bucket.

---

## 2026-06-24 - Использование Gemini Vision для распознавания заданий с доски
- **Status:** accepted
- **Decision:** При быстром добавлении ДЗ прикрепленное фото конвертируется в Base64 и отправляется в существующий Gemini API вместе с аудио/текстовым запросом.
- **Why:** Позволяет ИИ извлечь номера задач, которые учитель написал на доске, без дополнительных библиотек OCR на клиенте.
- **Consequences:** Чуть увеличивает вес JSON payload-а и время ответа (зависит от скорости Vercel-прокси).
- **Rollback:** Убрать поле `base64Image` из `ai_service.dart`.

---

## 2026-06-23 - Внедрение единого дизайн-ядра (PremiumCard & ShimmerLoading)

- **Status:** accepted
- **Decision:** Использовать кастомные премиум-виджеты (PremiumCard с глассморфизмом, ShimmerLoading для скелетонов, SwipeUpToEnter) вместо стандартных компонентов Material Design
- **Why:** Стандартный Material 3 не подходит под премиальный стиль "Sahara Warm Minimalism"; кастомные виджеты инкапсулируют сложную логику анимаций и блюра, упрощая код экранов
- **Consequences:** Все новые карточки должны наследоваться/использовать `PremiumCard`; для индикации загрузки списков обязательно использовать `ShimmerLoading`
- **Rollback:** Заменить `PremiumCard` на `Card` из Flutter, убрать блюр и анимации нажатия

---

## 2026-06-01 - Firestore через REST API напрямую (без FlutterFire)

- **Status:** accepted
- **Decision:** Обращаться к Firestore через `https://firestore.googleapis.com/v1/...` напрямую, без FlutterFire SDK
- **Why:** FlutterFire добавляет тяжёлые нативные зависимости; REST API легче, работает на всех платформах одинаково, проще контролировать заголовки и токены
- **Consequences:** Нельзя использовать `StreamBuilder` от FlutterFire; все запросы ручные через `http`; нужно самостоятельно парсить Firestore-формат (`stringValue`, `mapValue` и т.д.)
- **Rollback:** Добавить `firebase_core`, `cloud_firestore` в pubspec.yaml и переписать `firestore_service.dart`

---

## 2026-06-05 - Gemini API через Vercel-прокси

- **Status:** accepted
- **Decision:** AI-запросы проходят через задеплоенный Vercel-прокси (`vercel-proxy-delta-red.vercel.app/api/api/gemini`), а не напрямую к Google AI API
- **Why:** Прямые запросы с клиента раскрывают API-ключ в коде приложения; прокси скрывает ключ на сервере
- **Consequences:** Все AI-запросы зависят от доступности Vercel-сервера; при смене ключа — менять только на сервере; добавляется ~50–100ms задержки
- **Rollback:** Заменить `_apiUrl` в `ai_service.dart` на прямой Google AI endpoint и вернуть ключ из `.env`

---

## 2026-06-08 - Riverpod 3 как state management

- **Status:** accepted
- **Decision:** Использовать `flutter_riverpod ^3.3.2` с `@riverpod`-аннотациями и code generation
- **Why:** Типобезопасность, DI из коробки, хорошо тестируется; Riverpod 3 — актуальная версия с улучшенным API
- **Consequences:** После изменения провайдеров нужно запускать `dart run build_runner build`; нельзя смешивать с Provider или setState-подходом
- **Rollback:** Переписать провайдеры на `ChangeNotifier` + `Provider` — объём работы большой

---

## 2026-06-10 - go_router для навигации

- **Status:** accepted
- **Decision:** Навигация через `go_router ^17.3.0`, декларативный роутинг
- **Why:** Navigator 1.0 не поддерживает deep links и web-совместимость; go_router — рекомендованное решение Flutter-команды
- **Consequences:** Все переходы только через `context.go()` / `context.push()`; нет императивного `Navigator.push`
- **Rollback:** Переписать `router/` на Navigator 1.0 — возможно, но долго

---

## 2026-06-12 - freezed + json_serializable для моделей

- **Status:** accepted
- **Decision:** Все модели данных (`Lesson`, `HomeworkItem`) через `freezed` + `json_serializable`
- **Why:** Иммутабельность, `copyWith`, `==`/`hashCode` из коробки; исключает ошибки мутации состояния
- **Consequences:** После изменения модели нужно запускать `dart run build_runner build --delete-conflicting-outputs`; генерируются файлы `.freezed.dart` и `.g.dart`
- **Rollback:** Убрать аннотации, написать `toJson`/`fromJson` вручную

---

## 2026-06-15 - Система классов с кодом вступления

- **Status:** accepted
- **Decision:** Ученик создаёт класс (становится admin) или вступает по короткому коду; расписание и ДЗ изолированы по `classId`
- **Why:** Приложение должно поддерживать несколько классов с разным расписанием; код вступления прост и не требует приглашений
- **Consequences:** Весь CRUD ДЗ идёт в `/classes/{classId}/homework`; нужно хранить `classId` после входа
- **Rollback:** Убрать систему классов, вернуться к глобальной коллекции `/homework` — потеря изоляции данных

---

## 2026-06-18 - Оффлайн-кэш ДЗ в SharedPreferences

- **Status:** accepted
- **Decision:** ДЗ кэшируются в памяти (TTL 20 сек) и на диске (`SharedPreferences`) под ключом `offline_homework_{classId}`
- **Why:** Мобильное приложение должно работать при плохом интернете; кэш даёт мгновенный отклик
- **Consequences:** Данные могут быть устаревшими до 20 сек; при смене класса кэш сбрасывается вручную
- **Rollback:** Убрать `_cachedHomework` и `_persistHomework` — каждый запрос будет сетевым

---

## 2026-06-21 - flutter_secure_storage для токенов авторизации

- **Status:** accepted
- **Decision:** Firebase Auth токены (`idToken`, `refreshToken`) хранятся в `flutter_secure_storage`, а не в `SharedPreferences`
- **Why:** `SharedPreferences` хранит данные в открытом виде; `flutter_secure_storage` использует Keychain (iOS) / Keystore (Android)
- **Consequences:** На Android требует минимум API 23; на десктопе поведение отличается
- **Rollback:** Перенести токены в `SharedPreferences` — снижение безопасности
