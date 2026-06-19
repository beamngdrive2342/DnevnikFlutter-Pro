# Graph Report - .  (2026-06-20)

## Corpus Check
- 28 files · ~41,103 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 935 nodes · 1185 edges · 65 communities (49 shown, 16 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Data Firestore Component|Data Firestore Component]]
- [[_COMMUNITY_Widgets Premium Component|Widgets Premium Component]]
- [[_COMMUNITY_Runner Appdelegate Component|Runner Appdelegate Component]]
- [[_COMMUNITY_Theme Theme Component|Theme Theme Component]]
- [[_COMMUNITY_Widgets Ai Component|Widgets Ai Component]]
- [[_COMMUNITY_Screens Main Component|Screens Main Component]]
- [[_COMMUNITY_Runner Win32 Component|Runner Win32 Component]]
- [[_COMMUNITY_Theme App Component|Theme App Component]]
- [[_COMMUNITY_Screens Diary Component|Screens Diary Component]]
- [[_COMMUNITY_Screens Create Component|Screens Create Component]]
- [[_COMMUNITY_Data Schedule Component|Data Schedule Component]]
- [[_COMMUNITY_Screens Admin Component|Screens Admin Component]]
- [[_COMMUNITY_Data Auth Component|Data Auth Component]]
- [[_COMMUNITY_Admin Class Component|Admin Class Component]]
- [[_COMMUNITY_Data Schedule Component|Data Schedule Component]]
- [[_COMMUNITY_Widgets Network Component|Widgets Network Component]]
- [[_COMMUNITY_Screens Add Component|Screens Add Component]]
- [[_COMMUNITY_Utils App Component|Utils App Component]]
- [[_COMMUNITY_Runner My Component|Runner My Component]]
- [[_COMMUNITY_Admin Class Component|Admin Class Component]]
- [[_COMMUNITY_Providers Auth Component|Providers Auth Component]]
- [[_COMMUNITY_Screens Join Component|Screens Join Component]]
- [[_COMMUNITY_Screens Welcome Component|Screens Welcome Component]]
- [[_COMMUNITY_Utils Image Component|Utils Image Component]]
- [[_COMMUNITY_Test Test Component|Test Test Component]]
- [[_COMMUNITY_Windows Runner Component|Windows Runner Component]]
- [[_COMMUNITY_Utils Image Component|Utils Image Component]]
- [[_COMMUNITY_Web Manifest Component|Web Manifest Component]]
- [[_COMMUNITY_Windows Runner Component|Windows Runner Component]]
- [[_COMMUNITY_Screens Auth Component|Screens Auth Component]]
- [[_COMMUNITY_Widgets Fast Component|Widgets Fast Component]]
- [[_COMMUNITY_Data Ai Component|Data Ai Component]]
- [[_COMMUNITY_Router App Component|Router App Component]]
- [[_COMMUNITY_Admin Admin Component|Admin Admin Component]]
- [[_COMMUNITY_Diary Calendar Component|Diary Calendar Component]]
- [[_COMMUNITY_Screens Welcome Component|Screens Welcome Component]]
- [[_COMMUNITY_Diary Lesson Component|Diary Lesson Component]]
- [[_COMMUNITY_Ephemeral Flutter Component|Ephemeral Flutter Component]]
- [[_COMMUNITY_Package Dnevnik Component|Package Dnevnik Component]]
- [[_COMMUNITY_Plugins Generatedpluginregistrant Component|Plugins Generatedpluginregistrant Component]]
- [[_COMMUNITY_Api Gemini Component|Api Gemini Component]]
- [[_COMMUNITY_Windows Runner Component|Windows Runner Component]]
- [[_COMMUNITY_Dnevnik App Component|Dnevnik App Component]]
- [[_COMMUNITY_Route Create Component|Route Create Component]]
- [[_COMMUNITY_Runner Generatedpluginregistrant Component|Runner Generatedpluginregistrant Component]]
- [[_COMMUNITY_C Src Component|C Src Component]]
- [[_COMMUNITY_C Src Component|C Src Component]]
- [[_COMMUNITY_Concept Shared Component|Concept Shared Component]]
- [[_COMMUNITY_Auth Gate Component|Auth Gate Component]]
- [[_COMMUNITY_Create Class Component|Create Class Component]]
- [[_COMMUNITY_Diaryscreen Component|Diaryscreen Component]]
- [[_COMMUNITY_Join Class Component|Join Class Component]]
- [[_COMMUNITY_Main Screen Component|Main Screen Component]]
- [[_COMMUNITY_Materialpageroute Component|Materialpageroute Component]]
- [[_COMMUNITY_Package Crypto Component|Package Crypto Component]]
- [[_COMMUNITY_Welcome Screen Component|Welcome Screen Component]]

## God Nodes (most connected - your core abstractions)
1. `_` - 25 edges
2. `authProvider` - 11 edges
3. `Create()` - 10 edges
4. `MessageHandler()` - 10 edges
5. `WndProc()` - 9 edges
6. `_MyApplication` - 7 edges
7. `HWND` - 7 edges
8. `WindowClassRegistrar` - 7 edges
9. `Destroy()` - 7 edges
10. `MessageHandler()` - 6 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `OnCreate()` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/flutter/generated_plugin_registrant.cc
- `OnCreate()` --calls--> `GetClientArea()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/runner/win32_window.cpp

## Import Cycles
- None detected.

## Communities (65 total, 16 thin omitted)

### Community 0 - "Data Firestore Component"
Cohesion: 0.04
Nodes (50): auth_service.dart, addHomework, _applyLocalDoneState, _cachedHomework, _cacheExpiresAt, _cacheTtl, _classId, clearClassId (+42 more)

### Community 1 - "Widgets Premium Component"
Cohesion: 0.05
Nodes (44): Animation, AnimationController, CustomPainter, dart:math, Offset, OverlayEntry, SingleTickerProviderStateMixin, Widget (+36 more)

### Community 2 - "Runner Appdelegate Component"
Cohesion: 0.05
Nodes (30): Any, Cocoa, file_selector_macos, Flutter, RegisterGeneratedPlugins(), flutter_secure_storage_darwin, FlutterAppDelegate, FlutterImplicitEngineBridge (+22 more)

### Community 3 - "Theme Theme Component"
Cohesion: 0.05
Nodes (41): app_theme.dart, Color, ConsumerWidget, dart:async, DiaryTopBar, _bootstrapRuntime, build, _configureDisplayMode (+33 more)

### Community 4 - "Widgets Ai Component"
Cohesion: 0.05
Nodes (42): AIChatActivity get, ChangeNotifier, ImagePicker, TextEditingController, Timer?, _activity, AIChatActivity, AIChatController (+34 more)

### Community 5 - "Screens Main Component"
Cohesion: 0.06
Nodes (41): _DayEditor, _DayEditorState, AutomaticKeepAliveClientMixin, bool get, GlobalKey, PageController, ../screens/add_homework_modal.dart, ../screens/admin_panel_screen.dart (+33 more)

### Community 6 - "Runner Win32 Component"
Cohesion: 0.09
Nodes (34): RegisterPlugins(), PluginRegistry, Point, RECT, OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable() (+26 more)

### Community 7 - "Theme App Component"
Cohesion: 0.05
Nodes (39): @immutable, static const AppPalette, static const Color, static ThemeData get, AppPalette, AppTheme, bg, _buildTheme (+31 more)

### Community 8 - "Screens Diary Component"
Cohesion: 0.06
Nodes (35): diary/diary_top_bar.dart, package:gal/gal.dart, build, _buildDetailsSectionTitle, _buildHomeworkImageCard, _buildHomeworkKey, _buildHomeworkLookup, _buildHomeworkTextCard (+27 more)

### Community 9 - "Screens Create Component"
Cohesion: 0.06
Nodes (33): _adminPassC, _adminPassConfirmC, _availableSubjects, build, _buildDayEditor, _buildField, _classNameC, _createClass (+25 more)

### Community 10 - "Data Schedule Component"
Cohesion: 0.06
Nodes (32): allSubjects, classCode, classId, className, ClassSchedule, _dayPrefixes, defaultLessonTimes, defaultSubjects (+24 more)

### Community 11 - "Screens Admin Component"
Cohesion: 0.06
Nodes (32): AdminPanelScreen, AdminPanelScreenState, build, _buildEmptyState, _buildList, _buildTabButton, _buildTopBar, createState (+24 more)

### Community 12 - "Data Auth Component"
Cohesion: 0.06
Nodes (30): AuthService, _base, _buildClassDoc, _buildScheduleMap, _client, createClass, _databaseId, deleteClass (+22 more)

### Community 13 - "Admin Class Component"
Cohesion: 0.07
Nodes (28): _addLessonForDay, build, _buildDangerZoneCard, _buildDayEditorTab, _buildInfoCard, _buildScheduleEditor, _classCode, classId (+20 more)

### Community 14 - "Data Schedule Component"
Cohesion: 0.08
Nodes (28): @freezed, @JsonSerializable, @unfreezed, class, hashCode, HomeworkItemPatterns, id, identical (+20 more)

### Community 15 - "Widgets Network Component"
Cohesion: 0.07
Nodes (27): BoxFit, double?, Future, static const Duration, static const int, static final Map, ../utils/image_data.dart, build (+19 more)

### Community 16 - "Screens Add Component"
Cohesion: 0.07
Nodes (27): ../data/ai_service.dart, package:image_picker/image_picker.dart, captureBoardPhoto, doSubmit, fieldSurface, formLabel, imagePicker, isQuickMode (+19 more)

### Community 17 - "Utils App Component"
Cohesion: 0.07
Nodes (25): library, return, app_date_utils, date, day, defaultHomeworkDeadline, formatDate, formatDateIso (+17 more)

### Community 18 - "Runner My Component"
Cohesion: 0.10
Nodes (22): FlPluginRegistry, fl_register_plugins(), FlView, GApplication, gboolean, gchar, GObject, GtkApplication (+14 more)

### Community 19 - "Admin Class Component"
Cohesion: 0.17
Nodes (16): ClassSettingsTab, ClassSettingsTabState, _confirmDeleteClass, ConsumerState, ConsumerStatefulWidget, build, authProvider, CreateClassScreen (+8 more)

### Community 20 - "Providers Auth Component"
Cohesion: 0.12
Nodes (15): AuthState, ../data/auth_service.dart, ../data/firestore_service.dart, Notifier, AuthNotifier, AuthState, AuthStatus, build (+7 more)

### Community 21 - "Screens Join Component"
Cohesion: 0.13
Nodes (14): AppPalette get, package:flutter/services.dart, build, _codeC, createState, dispose, _error, formatEditUpdate (+6 more)

### Community 22 - "Screens Welcome Component"
Cohesion: 0.13
Nodes (14): dart:ui, IconData, createState, dispose, _emailC, _error, _field, icon (+6 more)

### Community 23 - "Utils Image Component"
Cohesion: 0.15
Nodes (12): Client? client,
  Duration, dart:typed_data, commaIndex, decodeInlineImageData, encodeInlineImageData, inferImageMimeType, isInlineImageData, isRemoteImageUrl (+4 more)

### Community 24 - "Test Test Component"
Cohesion: 0.18
Nodes (10): dart:convert, package:http/http.dart, apiKey, client, main, models, base, client (+2 more)

### Community 25 - "Windows Runner Component"
Cohesion: 0.23
Nodes (9): _In_, _In_opt_, wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), vector, string (+1 more)

### Community 26 - "Utils Image Component"
Cohesion: 0.18
Nodes (10): dart:io, image_data.dart, package:flutter/foundation.dart, package:path_provider/path_provider.dart, cleanupTemporaryPickerFiles, maxEmbeddedImageChars, null, pickedImageMaxSide (+2 more)

### Community 27 - "Web Manifest Component"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 28 - "Windows Runner Component"
Cohesion: 0.22
Nodes (8): DartProject, MessageHandler(), HWND, LPARAM, LRESULT, FlutterWindow(), UINT, WPARAM

### Community 29 - "Screens Auth Component"
Cohesion: 0.22
Nodes (8): ../data/schedule_data.dart, package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, ../providers/auth_provider.dart, AuthGate, build, ../theme/app_theme.dart, ../../widgets/theme_switch_button.dart

### Community 30 - "Widgets Fast Component"
Cohesion: 0.20
Nodes (9): double get, PageScrollPhysics, SpringDescription get, applyTo, dragStartDistanceMotionThreshold, FastPageScrollPhysics, minFlingDistance, minFlingVelocity (+1 more)

### Community 31 - "Data Ai Component"
Cohesion: 0.22
Nodes (8): Client, AIService, _apiUrl, _client, _extractQuickHomeworkJson, getAIResponse, recognizeQuickHomework, static const String

### Community 32 - "Router App Component"
Cohesion: 0.22
Nodes (8): GoRouter, package:go_router/go_router.dart, authState, screens/auth_gate.dart, ../screens/create_class_screen.dart, ../screens/join_class_screen.dart, ../screens/main_screen.dart, ../screens/welcome_screen.dart

### Community 33 - "Admin Admin Component"
Cohesion: 0.25
Nodes (7): build, hw, images, onDelete, onEdit, List, ../network_photo.dart

### Community 34 - "Diary Calendar Component"
Cohesion: 0.25
Nodes (7): DateTime, build, days, _isSameDay, scrollController, selectedDayIndex, today

### Community 35 - "Screens Welcome Component"
Cohesion: 0.29
Nodes (7): AdminHomeworkCard, CalendarStrip, _WelcomeButton, WelcomeScreen, StatelessWidget, _PhotoStateBox, ThemeSwitchButton

### Community 36 - "Diary Lesson Component"
Cohesion: 0.29
Nodes (6): build, customHw, lesson, LessonCard, onTap, VoidCallback

### Community 37 - "Ephemeral Flutter Component"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 38 - "Package Dnevnik Component"
Cohesion: 0.40
Nodes (4): package:dnevnik_app/main.dart, package:dnevnik_app/screens/auth_gate.dart, package:flutter_test/flutter_test.dart, main

### Community 43 - "Route Create Component"
Cohesion: 0.67
Nodes (3): Route /create, Route /join, build

## Knowledge Gaps
- **572 isolated node(s):** `SBFrame`, `SBDebugger`, `flutter_export_environment.sh script`, `UIApplication`, `Any` (+567 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **16 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `Data Schedule Component` to `Utils App Component`?**
  _High betweenness centrality (0.034) - this node is a cross-community bridge._
- **What connects `SBFrame`, `SBDebugger`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.` to the rest of the system?**
  _573 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Data Firestore Component` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._
- **Should `Widgets Premium Component` be split into smaller, more focused modules?**
  _Cohesion score 0.0463768115942029 - nodes in this community are weakly interconnected._
- **Should `Runner Appdelegate Component` be split into smaller, more focused modules?**
  _Cohesion score 0.05496828752642706 - nodes in this community are weakly interconnected._
- **Should `Theme Theme Component` be split into smaller, more focused modules?**
  _Cohesion score 0.048625792811839326 - nodes in this community are weakly interconnected._
- **Should `Widgets Ai Component` be split into smaller, more focused modules?**
  _Cohesion score 0.046511627906976744 - nodes in this community are weakly interconnected._