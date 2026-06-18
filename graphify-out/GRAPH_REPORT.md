# Graph Report - .  (2026-06-19)

## Corpus Check
- Corpus is ~37,224 words - fits in a single context window. You may not need a graph.

## Summary
- 856 nodes · 1063 edges · 44 communities (38 shown, 6 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 11 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Admin Panel UI|Admin Panel UI]]
- [[_COMMUNITY_App Entrypoint & Setup|App Entrypoint & Setup]]
- [[_COMMUNITY_Class Schedule Schema|Class Schedule Schema]]
- [[_COMMUNITY_UI Custom Painting & Effects|UI Custom Painting & Effects]]
- [[_COMMUNITY_Firestore Data Operations|Firestore Data Operations]]
- [[_COMMUNITY_AI Chat Widget & Logic|AI Chat Widget & Logic]]
- [[_COMMUNITY_macOS Native Bridges|macOS Native Bridges]]
- [[_COMMUNITY_App Theme & Styles|App Theme & Styles]]
- [[_COMMUNITY_Homework Creation UI|Homework Creation UI]]
- [[_COMMUNITY_Windows Win32 Windowing|Windows Win32 Windowing]]
- [[_COMMUNITY_Class Creation UI|Class Creation UI]]
- [[_COMMUNITY_Image Files & System Paths|Image Files & System Paths]]
- [[_COMMUNITY_Diary & Calendar UI|Diary & Calendar UI]]
- [[_COMMUNITY_Common Top Bars & Navigation|Common Top Bars & Navigation]]
- [[_COMMUNITY_Main Navigation Shell|Main Navigation Shell]]
- [[_COMMUNITY_Image Rendering Widgets|Image Rendering Widgets]]
- [[_COMMUNITY_User Auth Service|User Auth Service]]
- [[_COMMUNITY_Linux GTK Platform Runner|Linux GTK Platform Runner]]
- [[_COMMUNITY_Join Class UI|Join Class UI]]
- [[_COMMUNITY_Authentication Router|Authentication Router]]
- [[_COMMUNITY_Admin Tab Layouts|Admin Tab Layouts]]
- [[_COMMUNITY_Services Integration Tests|Services Integration Tests]]
- [[_COMMUNITY_Windows App Entrypoint|Windows App Entrypoint]]
- [[_COMMUNITY_PWA Web Settings|PWA Web Settings]]
- [[_COMMUNITY_Gemini AI Service Client|Gemini AI Service Client]]
- [[_COMMUNITY_Windows Shell Engine|Windows Shell Engine]]
- [[_COMMUNITY_LLDB Debugger Utilities|LLDB Debugger Utilities]]
- [[_COMMUNITY_Core Concepts & Config|Core Concepts & Config]]
- [[_COMMUNITY_Widget Behavior Tests|Widget Behavior Tests]]
- [[_COMMUNITY_Android Plugin Registry|Android Plugin Registry]]
- [[_COMMUNITY_Windows Shell Declarations|Windows Shell Declarations]]
- [[_COMMUNITY_Android App Entrypoint|Android App Entrypoint]]
- [[_COMMUNITY_iOS Plugin Registrant|iOS Plugin Registrant]]
- [[_COMMUNITY_iOS Build Config|iOS Build Config]]
- [[_COMMUNITY_macOS Build Config|macOS Build Config]]

## God Nodes (most connected - your core abstractions)
1. `Create()` - 10 edges
2. `MessageHandler()` - 10 edges
3. `WndProc()` - 9 edges
4. `_MyApplication` - 7 edges
5. `HWND` - 7 edges
6. `WindowClassRegistrar` - 7 edges
7. `Destroy()` - 7 edges
8. `MessageHandler()` - 6 edges
9. `AppDelegate` - 5 edges
10. `AdminPanelScreenState` - 5 edges

## Surprising Connections (you probably didn't know these)
- `Authentication and Gatekeeper Flow` --conceptually_related_to--> `dnevnik_app`  [INFERRED]
  lib/screens/auth_gate.dart → pubspec.yaml
- `Firestore Cloud Storage` --conceptually_related_to--> `dnevnik_app`  [INFERRED]
  lib/data/firestore_service.dart → pubspec.yaml
- `Google AI Studio API Integration` --conceptually_related_to--> `dnevnik_app`  [INFERRED]
  lib/data/ai_service.dart → pubspec.yaml
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc

## Import Cycles
- None detected.

## Communities (44 total, 6 thin omitted)

### Community 0 - "Admin Panel UI"
Cohesion: 0.04
Nodes (49): _addLessonForDay, build, _buildAdminCard, _buildDangerZoneCard, _buildDayEditorTab, _buildEmptyState, _buildInfoCard, _buildList (+41 more)

### Community 1 - "App Entrypoint & Setup"
Cohesion: 0.04
Nodes (45): app_theme.dart, Color, dart:async, double get, _bootstrapRuntime, build, _configureDisplayMode, initialize (+37 more)

### Community 2 - "Class Schedule Schema"
Cohesion: 0.04
Nodes (47): allSubjects, classCode, classId, className, ClassSchedule, copyWith, _dayPrefixes, deadline (+39 more)

### Community 3 - "UI Custom Painting & Effects"
Cohesion: 0.05
Nodes (45): Animation, AnimationController, CustomPainter, dart:math, Offset, OverlayEntry, SingleTickerProviderStateMixin, VoidCallback (+37 more)

### Community 4 - "Firestore Data Operations"
Cohesion: 0.04
Nodes (45): addHomework, _cachedHomework, _cacheExpiresAt, _cacheTtl, _classId, clearClassId, _client, databaseId (+37 more)

### Community 5 - "AI Chat Widget & Logic"
Cohesion: 0.05
Nodes (44): AIChatActivity get, ChangeNotifier, ImagePicker, String? get, TextEditingController, Timer?, _activity, AIChatActivity (+36 more)

### Community 6 - "macOS Native Bridges"
Cohesion: 0.06
Nodes (29): Any, Cocoa, file_selector_macos, Flutter, RegisterGeneratedPlugins(), FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate (+21 more)

### Community 7 - "App Theme & Styles"
Cohesion: 0.05
Nodes (41): @immutable, static const AppPalette, static const Color, static const double, static List, static ThemeData get, AppPalette, AppTheme (+33 more)

### Community 8 - "Homework Creation UI"
Cohesion: 0.05
Nodes (40): ../data/ai_service.dart, ../data/schedule_data.dart, DateTime, package:image_picker/image_picker.dart, captureBoardPhoto, doSubmit, fieldSurface, formLabel (+32 more)

### Community 9 - "Windows Win32 Windowing"
Cohesion: 0.09
Nodes (34): RegisterPlugins(), PluginRegistry, Point, RECT, OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable() (+26 more)

### Community 10 - "Class Creation UI"
Cohesion: 0.05
Nodes (40): List, Map, _adminPassC, _adminPassConfirmC, _availableSubjects, build, _buildDayEditor, _buildField (+32 more)

### Community 11 - "Image Files & System Paths"
Cohesion: 0.05
Nodes (36): Client? client,
  Duration, dart:io, dart:typed_data, image_data.dart, library, package:flutter/foundation.dart, package:path_provider/path_provider.dart, return (+28 more)

### Community 12 - "Diary & Calendar UI"
Cohesion: 0.05
Nodes (38): diary/diary_top_bar.dart, package:gal/gal.dart, build, _buildCalendarStrip, _buildDetailsSectionTitle, _buildHomeworkImageCard, _buildHomeworkKey, _buildHomeworkLookup (+30 more)

### Community 13 - "Common Top Bars & Navigation"
Cohesion: 0.06
Nodes (33): ../auth_gate.dart, create_class_screen.dart, dart:ui, ../data/auth_service.dart, build, DiaryTopBar, IconData, join_class_screen.dart (+25 more)

### Community 14 - "Main Navigation Shell"
Cohesion: 0.07
Nodes (30): bool get, GlobalKey, PageController, ../screens/add_homework_modal.dart, ../screens/admin_panel_screen.dart, ../screens/diary_screen.dart, _adminKey, _adminScreen (+22 more)

### Community 15 - "Image Rendering Widgets"
Cohesion: 0.07
Nodes (28): BoxFit, double?, Future, static const int, static final Map, ../utils/image_data.dart, build, _cache (+20 more)

### Community 16 - "User Auth Service"
Cohesion: 0.07
Nodes (26): AuthService, _base, _buildClassDoc, _buildScheduleMap, _client, createClass, _databaseId, deleteClass (+18 more)

### Community 17 - "Linux GTK Platform Runner"
Cohesion: 0.11
Nodes (22): FlPluginRegistry, fl_register_plugins(), FlView, GApplication, gboolean, gchar, GObject, GtkApplication (+14 more)

### Community 18 - "Join Class UI"
Cohesion: 0.13
Nodes (15): package:flutter/services.dart, build, _codeC, createState, dispose, _error, formatEditUpdate, JoinClassScreen (+7 more)

### Community 19 - "Authentication Router"
Cohesion: 0.18
Nodes (11): AppPalette get, ../data/firestore_service.dart, main_screen.dart, AuthGate, _AuthGateState, build, _checkSession, createState (+3 more)

### Community 20 - "Admin Tab Layouts"
Cohesion: 0.23
Nodes (12): AutomaticKeepAliveClientMixin, DiaryScreen, AdminPanelScreen, AdminPanelScreenState, _ClassSettingsTab, _ClassSettingsTabState, _DayEditor, _DayEditorState (+4 more)

### Community 21 - "Services Integration Tests"
Cohesion: 0.18
Nodes (10): dart:convert, package:http/http.dart, apiKey, client, main, models, base, client (+2 more)

### Community 22 - "Windows App Entrypoint"
Cohesion: 0.23
Nodes (9): _In_, _In_opt_, wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), vector, string (+1 more)

### Community 23 - "PWA Web Settings"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 24 - "Gemini AI Service Client"
Cohesion: 0.20
Nodes (9): Client, AIService, _apiKey, _apiUrl, _client, _extractQuickHomeworkJson, getAIResponse, recognizeQuickHomework (+1 more)

### Community 25 - "Windows Shell Engine"
Cohesion: 0.22
Nodes (8): DartProject, MessageHandler(), HWND, LPARAM, LRESULT, FlutterWindow(), UINT, WPARAM

### Community 26 - "LLDB Debugger Utilities"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 27 - "Core Concepts & Config"
Cohesion: 0.40
Nodes (5): Authentication and Gatekeeper Flow, Firestore Cloud Storage, Google AI Studio API Integration, SharedPreferences Cache, dnevnik_app

### Community 28 - "Widget Behavior Tests"
Cohesion: 0.40
Nodes (4): package:dnevnik_app/main.dart, package:dnevnik_app/screens/auth_gate.dart, package:flutter_test/flutter_test.dart, main

## Knowledge Gaps
- **551 isolated node(s):** `SBFrame`, `SBDebugger`, `flutter_export_environment.sh script`, `UIApplication`, `Any` (+546 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `HomeworkItem` connect `Class Schedule Schema` to `Admin Panel UI`, `Firestore Data Operations`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Why does `DiaryScreenState` connect `Admin Tab Layouts` to `Diary & Calendar UI`, `Main Navigation Shell`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **What connects `SBFrame`, `SBDebugger`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.` to the rest of the system?**
  _552 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Admin Panel UI` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `App Entrypoint & Setup` be split into smaller, more focused modules?**
  _Cohesion score 0.04421768707482993 - nodes in this community are weakly interconnected._
- **Should `Class Schedule Schema` be split into smaller, more focused modules?**
  _Cohesion score 0.041666666666666664 - nodes in this community are weakly interconnected._
- **Should `UI Custom Painting & Effects` be split into smaller, more focused modules?**
  _Cohesion score 0.04625346901017576 - nodes in this community are weakly interconnected._