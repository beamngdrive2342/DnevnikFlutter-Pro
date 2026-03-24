---
name: flutter-optimization
description: >
  Optimize Flutter applications for performance, size, and user experience.
  Use this skill whenever the user mentions Flutter performance issues, slow UI,
  jank, large APK/IPA size, memory leaks, slow startup, laggy animations,
  excessive rebuilds, or asks to "speed up", "optimize", "improve performance",
  or "reduce size" of a Flutter app. Also trigger when the user shares Flutter
  code and asks for a review — always check for optimization opportunities.
  Even if the user just asks "why is my Flutter app slow?", use this skill.
---

# Flutter App Optimization Skill

A comprehensive guide to diagnosing and fixing performance issues in Flutter apps.

## Quick Diagnosis Checklist

Before diving into fixes, identify the problem area:

1. **UI Jank / dropped frames** → See [Rendering & Animations](#rendering--animations)
2. **Slow startup** → See [App Startup](#app-startup)
3. **Large APK/IPA** → See [App Size](#app-size)
4. **High memory usage / leaks** → See [Memory Management](#memory-management)
5. **Slow network / data loading** → See [Network & Data](#network--data)
6. **Excessive rebuilds** → See [Widget Rebuilds](#widget-rebuilds)
7. **Slow lists** → See [Lists & Scrolling](#lists--scrolling)

---

## Rendering & Animations

### Enable Performance Overlay
```dart
MaterialApp(
  showPerformanceOverlay: true, // Shows FPS bars
)
```
- Top bar = GPU thread, Bottom bar = UI thread
- Both should stay **below the 16ms line** (60fps)

### Use `const` constructors everywhere possible
```dart
// ❌ Bad - rebuilds every time
Text('Hello')

// ✅ Good - compiled once
const Text('Hello')
```

### Avoid `opacity` widget for animations — use `AnimatedOpacity` or `FadeTransition`
```dart
// ❌ Triggers compositing layer, expensive
Opacity(opacity: 0.5, child: MyWidget())

// ✅ Animates on GPU, cheap
FadeTransition(opacity: animation, child: MyWidget())
```

### Use `RepaintBoundary` to isolate expensive widgets
```dart
RepaintBoundary(
  child: MyComplexAnimatedWidget(),
)
```
Prevents repaints from propagating up the widget tree.

### Prefer `CustomPainter` over stacked widgets for complex drawing
For complex shapes/charts, draw directly with Canvas — far fewer layers.

### Check for shader compilation jank
Run in profile mode and use `flutter run --profile`. If first-frame animations stutter, use **Impeller** (enabled by default on iOS since Flutter 3.10):
```yaml
# pubspec.yaml / ios/Runner/Info.plist
# Impeller is ON by default for iOS — no action needed
# For Android (experimental):
flutter:
  android:
    enable-impeller: true
```

---

## Widget Rebuilds

### Use `const` to prevent unnecessary rebuilds (see above)

### Split large `build()` methods into smaller widgets
```dart
// ❌ One giant build — everything rebuilds together
Widget build(BuildContext context) {
  return Column(children: [Header(), Body(), Footer()]);
}

// ✅ Separate StatelessWidgets — rebuild independently
class Header extends StatelessWidget { ... }
class Body extends StatelessWidget { ... }
```

### Use `Builder` or extract widgets instead of calling `setState` high up the tree

### Prefer `Selector` (provider) or `watch`/`select` (riverpod) over broad listeners
```dart
// ❌ Rebuilds on ANY state change
final count = ref.watch(counterProvider);

// ✅ Rebuilds only when `count` changes
final count = ref.watch(counterProvider.select((s) => s.count));
```

### Use `ValueNotifier` + `ValueListenableBuilder` for local UI state
```dart
final _counter = ValueNotifier<int>(0);

ValueListenableBuilder<int>(
  valueListenable: _counter,
  builder: (_, value, __) => Text('$value'),
)
```

### Profile rebuilds with Flutter DevTools
Open DevTools → **Widget Rebuild Stats** tab. Widgets highlighted in red rebuild too often.

---

## Lists & Scrolling

### Always use `ListView.builder` for long lists
```dart
// ❌ Builds ALL items at once
ListView(children: items.map((e) => ItemWidget(e)).toList())

// ✅ Builds only visible items
ListView.builder(
  itemCount: items.length,
  itemBuilder: (_, i) => ItemWidget(items[i]),
)
```

### Use `itemExtent` or `prototypeItem` for fixed-height lists
```dart
ListView.builder(
  itemExtent: 72.0, // Skip layout calculation — big speedup
  itemBuilder: (_, i) => MyListTile(items[i]),
)
```

### Paginate data — never load the full list at once
Load 20–50 items, fetch more on scroll:
```dart
scrollController.addListener(() {
  if (scrollController.position.pixels >= 
      scrollController.position.maxScrollExtent - 200) {
    loadMore();
  }
});
```

### Use `cached_network_image` for images in lists
```yaml
dependencies:
  cached_network_image: ^3.3.0
```
```dart
CachedNetworkImage(
  imageUrl: url,
  placeholder: (_, __) => const ShimmerPlaceholder(),
)
```

### Avoid `ClipRRect` on list tiles — use `borderRadius` in `BoxDecoration` instead

---

## App Startup

### Use deferred imports for rarely-used features
```dart
import 'heavy_feature.dart' deferred as heavyFeature;

// Load only when needed
await heavyFeature.loadLibrary();
heavyFeature.HeavyWidget();
```

### Minimize work in `main()` and top-level constructors
Move expensive initialization (DB, analytics, etc.) to after first frame:
```dart
void main() {
  runApp(const MyApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Heavy init here — after first frame is shown
    initDatabase();
    initAnalytics();
  });
}
```

### Use `flutter_native_splash` for a proper splash screen
Avoids white flash on startup.

### Reduce plugin initialization
Every plugin adds startup time. Audit `pubspec.yaml` — remove unused ones.

---

## App Size

### Build in release mode with size analysis
```bash
flutter build apk --release --analyze-size
flutter build ipa --release --analyze-size
```
Opens an interactive size breakdown in DevTools.

### Split APK by ABI (Android)
```bash
flutter build apk --split-per-abi
```
Reduces APK from ~20MB to ~6–8MB per architecture.

### Enable R8/ProGuard (Android) — already on by default in release builds
Verify in `android/app/build.gradle`:
```groovy
buildTypes {
  release {
    minifyEnabled true
    shrinkResources true
  }
}
```

### Compress and resize images
- Use WebP instead of PNG/JPEG
- Use `flutter_image_compress` package
- Use SVG (`flutter_svg`) for icons instead of raster images

### Remove unused assets and fonts
Each font style (~50–200KB) adds to size. Only declare what you use:
```yaml
fonts:
  - family: Roboto
    fonts:
      - asset: fonts/Roboto-Regular.ttf  # Only include used weights
```

### Audit packages
```bash
flutter pub deps --style=compact
```
Remove unused packages. Watch out for packages that bundle native code.

---

## Memory Management

### Always cancel subscriptions and dispose controllers
```dart
class MyState extends State<MyWidget> {
  late StreamSubscription _sub;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _sub = stream.listen(onData);
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _sub.cancel();   // ✅ Must cancel
    _ctrl.dispose(); // ✅ Must dispose
    super.dispose();
  }
}
```

### Use `AutoDispose` in Riverpod to auto-clean providers
```dart
final myProvider = StateNotifierProvider.autoDispose<MyNotifier, MyState>(
  (ref) => MyNotifier(),
);
```

### Don't hold large objects in state indefinitely
Clear image caches if memory pressure is high:
```dart
PaintingBinding.instance.imageCache.clear();
PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB cap
```

### Use `flutter_memory_info` or DevTools Memory tab to find leaks
Look for objects that accumulate over time in the allocation timeline.

---

## Network & Data

### Cache API responses
Use `dio` with `dio_cache_interceptor`:
```dart
final dio = Dio()..interceptors.add(
  DioCacheInterceptor(options: CacheOptions(store: MemCacheStore())),
);
```

### Use `compute()` for heavy JSON parsing (moves to background isolate)
```dart
final data = await compute(parseHeavyJson, rawJsonString);

List<MyModel> parseHeavyJson(String json) {
  return (jsonDecode(json) as List).map(MyModel.fromJson).toList();
}
```

### Use `json_serializable` or `freezed` — avoid manual `fromJson` in hot paths

### Compress requests and enable HTTP/2
Configure your backend. `dio` supports HTTP/2 automatically on newer Dart.

---

## Tools & Commands Reference

| Task | Command |
|------|---------|
| Run in profile mode | `flutter run --profile` |
| Analyze app size | `flutter build apk --analyze-size` |
| Open DevTools | `flutter pub global run devtools` |
| Check dependencies | `flutter pub deps` |
| Find outdated packages | `flutter pub outdated` |
| Analyze code | `flutter analyze` |

## Reference Files

- `references/devtools-guide.md` — Step-by-step DevTools profiling walkthrough
- `references/state-management-perf.md` — Performance comparison: Provider vs Riverpod vs BLoC vs GetX
- `references/platform-specific.md` — iOS vs Android specific optimizations

---

## How to Apply This Skill

1. **Ask the user** what symptoms they're seeing (jank, slow startup, large size, etc.)
2. **Look at their code** if they share it — scan for anti-patterns above
3. **Suggest the top 3 fixes** most likely to have impact, with code examples
4. **Recommend profiling tools** so they can measure before and after
5. **Prioritize** rendering > startup > size > memory (in that order for most apps)
