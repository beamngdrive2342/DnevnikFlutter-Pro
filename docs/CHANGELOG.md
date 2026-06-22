# Changelog — DnevnikFlutter

Все значимые изменения в проекте. Формат: [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/).

---

## [Unreleased]

---

## [2026-06-23]

### Added
- Базовый виджет `PremiumCard` (эффект глассморфизма, встроенная анимация нажатия).
- Глобальный лоадер-скелетон (`shimmer_loading.dart`) для сглаживания UI при загрузке расписания.
- Эффект свайпа вверх для входа на `welcome_screen.dart` (паттерн Swipe-up to Enter) с плавным BottomSheet модальным окном.

### Changed
- `LessonCard` полностью переписан на основе `PremiumCard` с микро-анимацией раскрытия (AnimatedSize).
- Позиция стрелочки раскрытия в `LessonCard` изменена (перемещена к времени урока) во избежание перекрытия FAB.

---

## [2026-06-22]

### Changed
- Редизайн экрана входа (Welcome Screen): применен новый минималистичный дизайн с радиальным свечением (RadialGradient) и строгими темными кнопками-плашками в оригинальных цветах.

---

## [2026-06-21]

### Security
- Gemini API-ключ вынесен на Vercel-прокси — клиент больше не хранит ключ напрямую
- Улучшена система авторизации Firebase Auth: токены хранятся в `flutter_secure_storage`

---

## [2026-06-18]

### Added
- Оффлайн-кэш домашних заданий: память (TTL 20 сек) + диск (`SharedPreferences`)
- Фоновое обновление ДЗ без блокировки UI (`_refreshHomeworkInBackground`)
- Автоматическая очистка устаревших ДЗ (старше 14 дней) через `_purgeExpiredHomework`

### Changed
- `FirestoreService.getHomework` — добавлены три уровня кэша: memory → disk → network

---

## [2026-06-15]

### Added
- Система классов: создание класса (`create_class_screen.dart`) и вступление по коду (`join_class_screen.dart`)
- Изоляция данных по `classId` — расписание и ДЗ отдельны для каждого класса
- Панель администратора (`admin_panel_screen.dart`) для управления расписанием класса

### Changed
- Firestore-коллекция ДЗ перенесена с `/homework` на `/classes/{classId}/homework`

---

## [2026-06-12]

### Added
- Модели данных `Lesson` и `HomeworkItem` через `freezed` + `json_serializable`
- `ClassSchedule` — статический синглтон для хранения расписания класса
- Цветовая маркировка предметов (`subjectColors`) для визуального различия

---

## [2026-06-10]

### Added
- Навигация через `go_router ^17.3.0`
- `auth_gate.dart` — автоматический роутинг в зависимости от состояния авторизации

---

## [2026-06-08]

### Added
- State management через `flutter_riverpod ^3.3.2`
- `auth_provider.dart` — провайдер состояния авторизации

---

## [2026-06-05]

### Added
- `ai_service.dart` — интеграция с Google Gemini API через Vercel-прокси
- AI-чат с контекстом расписания и ДЗ (`getAIResponse`)
- Умный парсинг ДЗ из текста (`recognizeQuickHomework`): «Алгебра на завтра номера 45 46» → структурированный объект
- Поддержка изображений в чате (base64 + mime type)

---

## [2026-06-01]

### Added
- Инициализация Flutter-проекта `dnevnik_app`
- `firestore_service.dart` — CRUD домашних заданий через Firestore REST API (без FlutterFire)
- `auth_service.dart` — Firebase Auth через REST API
- `diary_screen.dart` — экран дневника / списка ДЗ
- `add_homework_modal.dart` — модалка добавления ДЗ (вручную + AI-парсинг)
- `welcome_screen.dart` — экран онбординга
- `main_screen.dart` — главный экран с таб-навигацией
- Базовая тема и стили (`theme/`)

---

**Формат секций:** `Added` — новое, `Changed` — изменения, `Fixed` — исправления, `Removed` — удалённое, `Security` — безопасность
