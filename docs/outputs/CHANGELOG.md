# Changelog — DnevnikFlutter

Все значимые изменения в проекте. Формат: [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/).

---

## [Unreleased]

### Added
- **Profile Customization** (`profile_provider.dart`): Глобальный стейт-менеджер профиля ученика/админа. Имя и фото (в виде base64) сохраняются локально через `SharedPreferences` и `image_picker`.
- **Settings Screen** (`settings_screen.dart`): Новый полноценный экран настроек с 4 секциями:
  - «Профиль»: смена аватара и имени
  - «Внешний вид»: toggle темёмной/светлой темы
  - «Данные»: очистка локального кэша
  - «О приложении»: версия, ссылки на Privacy Policy и ToS, поддержка, лицензии
  - «Аккаунт»: выход, удаление аккаунта
- **Account Deletion** (обязательное требование Google Play): Новые методы `deleteAdminAccount()` и `deleteStudentAccount()` в `AuthService`. Удаление аккаунта admin удаляет весь класс + все ДЗ + всех участников + Firebase Auth аккаунт.
- **Privacy Policy & Terms of Service** (`docs/legal/`): Созданы юридические документы для публикации на GitHub Pages. Политика конфиденциальности описывает какие данные собираются, как используются и как удаляются.
- **Маршрут `/settings`** в `app_router.dart`.
- **Новые зависимости**: `url_launcher ^6.2.0` (открытие ссылок), `package_info_plus ^8.0.0` (версия приложения).

### Changed
- **Diary TopBar**: Кнопки отдельной смены темы и выхода из аккаунта заменены стильной кнопкой-пилюлей "Профиль" с аватаром пользователя.
- **UI/UX**: Полный отказ от эффектов прозрачности/glassmorphism (удалены BackdropFilter из диалогов) в пользу solid-цветов (palette.bg) для лучшей читаемости и производительности.
- **AndroidManifest.xml**: `android:label` изменён с `dnevnik_app` на `Школьный Дневник`. `READ/WRITE_EXTERNAL_STORAGE` ограничены `maxSdkVersion="32"` (deprecated на Android 13+), добавлен `READ_MEDIA_IMAGES`.

### Fixed
- **URL Launcher (Android 11+)**: Исправлена ошибка открытия внешних ссылок (Privacy Policy), метод `canLaunchUrl` заменен на блок `try-catch` при `launchUrl`.
- **GitHub Pages**: Выполнен коммит и отправка файлов `docs/legal` в ветку `main` для устранения ошибки 404 при открытии соглашений.

---

## [2026-07-05] — Скрытый AI-чат и Agentic OS

### Added
- Добавлен скрытый вызов AI-ассистента в админ-панели (вызывается долгим нажатием на кнопку `+`), с плавной анимацией выплывания.
- Внедрена файловая структура «Second Brain» (Agentic OS): файлы `index.md` в корне, `docs/` и `src/lib/`; папка `docs/` разделена на `raw`, `wiki`, `outputs`.
- Добавлен обязательный шаг `Lessons Learned` в рабочие навыки агента.

---

## [2026-06-30]

### Fixed
- **Vercel Proxy:** Исправлена критическая ошибка сборки прокси-сервера Gemini API на Vercel (возвращал 404 NOT_FOUND при любых запросах к API). В настройках проекта Vercel `rootDirectory` изменен с `.` на `src/vercel-proxy`, благодаря чему автоматический Git-билд теперь корректно находит и компилирует Edge-функцию `gemini.js` по пути `api/api/gemini.js`.

---

## [2026-06-27]

### Added
- Созданы экспериментальные виджеты `GeometrySolution1` и `GeometrySolution8` (в папке `widgets/geometry/`) для тестирования отрисовки чертежей через `CustomPaint`.

### Rejected
- Отклонён подход с ручной SVG-отрисовкой геометрических задач — слишком трудозатратно и хрупко.
- Отклонён `flutter_math_fork` для сложных математических формул (визуальные баги с `\cline`, `\underline`).
- Push-уведомления (FCM) отменены из-за конфликтов ESM/CJS в Vercel Edge Runtime.

---

## [2026-06-24]

### Added
- GitHub CDN для хранения 3400+ фотографий ГДЗ (APK вернулся к нормальным ~111 МБ).
- Gemini Vision для распознавания заданий с фото/доски при быстром добавлении ДЗ.

---

## [2026-06-23]

### Added
- Премиум-виджеты: `PremiumCard` (glassmorphism), `ShimmerLoading`, `SwipeUpToEnter`.
- Дизайн-система «Sahara Warm Minimalism» — кастомные цвета, шрифты, анимации.

---

## [2026-06-21]

### Security
- Gemini API-ключ скрыт за Vercel-прокси (больше не хранится на клиенте).
- Firebase Auth токены перенесены в `flutter_secure_storage` (Keychain/Keystore).