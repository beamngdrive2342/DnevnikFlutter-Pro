import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/ai_service.dart';
import '../data/auth_service.dart';
import '../data/firestore_service.dart';
import '../data/schedule_data.dart';
import '../theme/app_theme.dart';
import '../utils/app_date_utils.dart' as date_utils;
import '../utils/image_picker_utils.dart' as picker_utils;
import '../utils/subject_utils.dart' as subject_utils;
import '../widgets/top_notification.dart';

/// Shows the "Add Homework" bottom sheet modal.
///
/// [parentContext] — the calling screen's BuildContext.
/// [onHomeworkSaved] — callback invoked after homework is successfully saved.
Future<void> showAddHomeworkModal({
  required BuildContext parentContext,
  required Future<void> Function() onHomeworkSaved,
}) async {
  final messenger = ScaffoldMessenger.of(parentContext);
  final palette = AppTheme.colorsOf(parentContext);
  final imagePicker = ImagePicker();

  String? selectedSubject;
  final taskController = TextEditingController();
  final quickCommandController = TextEditingController();
  final pickedImagePaths = <String>[];
  DateTime selectedDeadline = date_utils.defaultHomeworkDeadline();
  bool isUploading = false;
  bool isQuickMode = true;
  bool isRecognizingQuick = false;
  String? quickRecognitionMessage;
  bool isTextbookGeometry = false;
  final modalSurface = palette.surface2.withValues(alpha: 1);
  final fieldSurface = palette.surface3.withValues(alpha: 1);

  Widget formLabel(String text) {
    return Text(text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: palette.onSurface2,
        ));
  }

  Future<void> pickImages(
    BuildContext sheetContext,
    StateSetter setModalState,
  ) async {
    final images = await imagePicker.pickMultiImage(
      imageQuality: picker_utils.pickedImageQuality,
      maxWidth: picker_utils.pickedImageMaxSide,
      maxHeight: picker_utils.pickedImageMaxSide,
    );
    if (images.isEmpty) {
      return;
    }
    if (!sheetContext.mounted) {
      return;
    }
    setModalState(() {
      for (final image in images) {
        if (!pickedImagePaths.contains(image.path)) {
          pickedImagePaths.add(image.path);
        }
      }
    });
  }

  Future<void> captureBoardPhoto(
    BuildContext sheetContext,
    StateSetter setModalState,
  ) async {
    final image = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: picker_utils.pickedImageQuality,
      maxWidth: picker_utils.pickedImageMaxSide,
      maxHeight: picker_utils.pickedImageMaxSide,
    );
    if (image == null) {
      return;
    }
    if (!sheetContext.mounted) return;
    setModalState(() {
      if (!pickedImagePaths.contains(image.path)) {
        pickedImagePaths.add(image.path);
      }
    });
  }

  Future<Map<String, dynamic>> recognizeQuickHomeworkAI(
      String adminText, List<String> imagePaths) async {
    final classId = FirestoreService.classId;
    if (classId == null || classId.isEmpty) {
      return {
        'subject': null,
        'deadline': null,
        'task': null,
        'fallback': true
      };
    }
    final loaded = await AuthService.loadClassData(classId);
    if (!loaded) {
      return {
        'subject': null,
        'deadline': null,
        'task': null,
        'fallback': true
      };
    }

    String? base64Image;
    if (imagePaths.isNotEmpty) {
      try {
        final bytes = File(imagePaths.first).readAsBytesSync();
        base64Image = base64Encode(bytes);
      } catch (e) {
        debugPrint('Error reading image for AI: $e');
      }
    }

    return AIService.recognizeQuickHomework(
      today: DateTime.now(),
      scheduleText: subject_utils.buildScheduleSummaryForAI(),
      adminText: adminText,
      base64Image: base64Image,
    );
  }

  Future<void> doSubmit({
    required void Function(VoidCallback) safeSetModalState,
    required BuildContext sheetContext,
  }) async {
    final taskText = taskController.text.trim();
    if (selectedSubject == null || taskText.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Заполните предмет и задание')),
      );
      return;
    }

    List<String> extractedNumbers = [];
    final isTextbookSubject = (selectedSubject == 'Геометрия' || selectedSubject == 'Алгебра');
    if (isTextbookSubject && isTextbookGeometry) {
      final matches = RegExp(r'\d+').allMatches(taskText);
      extractedNumbers = matches.map((m) => m.group(0)!).toList();
    }

    if (!subject_utils.hasSubjectOnDate(selectedSubject!, selectedDeadline)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'В этот день этого предмета нет, выберите другой день или предмет.'),
        ),
      );
      return;
    }

    try {
      safeSetModalState(() => isUploading = true);

      final embeddedImages = <String>[];
      bool hasError = false;
      final uploadResults = await Future.wait(
        pickedImagePaths.map(picker_utils.prepareEmbeddedImage),
      );
      for (final result in uploadResults) {
        if (result != null) {
          embeddedImages.add(result);
        } else {
          hasError = true;
        }
      }

      final totalImageChars =
          embeddedImages.fold<int>(0, (sum, item) => sum + item.length);
      if (totalImageChars > picker_utils.maxEmbeddedImageChars) {
        safeSetModalState(() => isUploading = false);
        if (!parentContext.mounted) return;
        messenger.showSnackBar(
          const SnackBar(
              content: Text(
                  'Слишком большие фото. Уменьшите количество или выберите более лёгкие изображения.')),
        );
        return;
      }

      if (hasError) {
        safeSetModalState(() => isUploading = false);
        if (!parentContext.mounted) return;
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Ошибка при подготовке фото. Попробуйте еще раз.')),
        );
        return;
      }

      final hw = HomeworkItem(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        subject: selectedSubject!,
        task: taskText,
        deadline: date_utils.formatDateIso(selectedDeadline),
        imageUrl: null,
        imageUrls: embeddedImages.isNotEmpty ? embeddedImages : null,
        fullResolutionUrls: null,
        done: false,
        fromSchedule: false,
        textbookNumbers: extractedNumbers,
      );

      final success = await FirestoreService.addHomework(hw);
      if (!parentContext.mounted) return;

      if (!success) {
        safeSetModalState(() => isUploading = false);
        messenger.showSnackBar(
          const SnackBar(content: Text('Ошибка при сохранении в базу данных.')),
        );
        return;
      }

      await onHomeworkSaved();
      if (sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
      }
      unawaited(picker_utils.cleanupTemporaryPickerFiles(pickedImagePaths));

      if (!parentContext.mounted) return;
      showTopNotification(
        parentContext,
        'Задание на ${date_utils.formatDate(selectedDeadline)} успешно добавлено',
      );
    } catch (e, st) {
      debugPrint('Save homework failed: $e\n$st');
      safeSetModalState(() => isUploading = false);
      if (!parentContext.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
            content: Text(
                'Произошла ошибка при сохранении задания. Попробуйте еще раз.')),
      );
    }
  }

  Future<void> recognizeQuickHomework(
    BuildContext sheetContext,
    StateSetter setModalState,
  ) async {
    final quickText = quickCommandController.text.trim();
    if (quickText.isEmpty) {
      setModalState(() {
        quickRecognitionMessage =
            'Введите или продиктуйте текст для быстрого добавления.';
      });
      return;
    }

    setModalState(() {
      isRecognizingQuick = true;
      quickRecognitionMessage = null;
    });

    final result = await recognizeQuickHomeworkAI(quickText, pickedImagePaths);
    if (!sheetContext.mounted) return;

    final recognizedSubject =
        subject_utils.matchRecognizedSubject(result['subject']);
    final recognizedDeadline =
        date_utils.parseHomeworkDeadline(result['deadline']);
    final bool fallback = result['fallback'] == true;

    bool canAutoSubmit = false;
    setModalState(() {
      selectedSubject = recognizedSubject;
      if (recognizedDeadline != null) {
        selectedDeadline = recognizedDeadline;
      }

      final recognizedTask = result['task']?.toString().trim();
      if (recognizedTask != null && recognizedTask.isNotEmpty) {
        taskController.text = recognizedTask;
      } else if (taskController.text.trim().isEmpty) {
        taskController.text = quickText;
      }

      // Check if we have enough info for auto-submission
      // We only auto-submit if fallback is false AND subject is valid for the date
      if (!fallback &&
          recognizedSubject != null &&
          recognizedDeadline != null &&
          taskController.text.trim().isNotEmpty &&
          subject_utils.hasSubjectOnDate(
              recognizedSubject, recognizedDeadline)) {
        canAutoSubmit = true;
      }

      if ((recognizedSubject == 'Геометрия' || recognizedSubject == 'Алгебра') &&
          result['textbookNumbers'] != null &&
          (result['textbookNumbers'] as List).isNotEmpty) {
        isTextbookGeometry = true;
      }

      if (canAutoSubmit) {
        // Keep isQuickMode = true and stay in "recognizing" state
        // until doSubmit handles the submission and closes the modal.
      } else {
        isRecognizingQuick = false;
        isQuickMode = false;
        quickRecognitionMessage =
            (recognizedSubject != null && recognizedDeadline != null)
                ? 'Поля заполнены автоматически. Проверьте и сохраните.'
                : 'Не всё удалось определить. Завершите заполнение вручную.';
      }
    });

    if (canAutoSubmit && sheetContext.mounted) {
      try {
        await doSubmit(
          safeSetModalState: (fn) {
            if (sheetContext.mounted) setModalState(fn);
          },
          sheetContext: sheetContext,
        );
      } finally {
        if (sheetContext.mounted) {
          setModalState(() => isRecognizingQuick = false);
        }
      }
    }
  }

  await showModalBottomSheet<void>(
    context: parentContext,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          void safeSetModalState(VoidCallback fn) {
            if (!ctx.mounted) return;
            setModalState(fn);
          }

          return PopScope(
            canPop: !isUploading,
            child: Container(
              margin:
                  EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
              decoration: BoxDecoration(
                color: modalSurface,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusXl)),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('Добавить задание',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontSerif,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w500,
                                        color: palette.onBg,
                                      )),
                                  Material(
                                    color: palette.surface2,
                                    borderRadius: BorderRadius.circular(100),
                                    child: InkWell(
                                      onTap: isUploading
                                          ? null
                                          : () => Navigator.of(ctx).pop(),
                                      borderRadius: BorderRadius.circular(100),
                                      child: SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: Icon(Icons.close_rounded,
                                            color: palette.onSurface2,
                                            size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (isQuickMode) ...[
                          Row(
                            children: [
                              // Big camera button
                              Expanded(
                                child: SizedBox(
                                  height: 64,
                                  child: ElevatedButton.icon(
                                    onPressed: isUploading || isRecognizingQuick
                                        ? null
                                        : () async {
                                            await captureBoardPhoto(
                                                ctx, setModalState);
                                          },
                                    icon: const Icon(Icons.photo_camera_rounded,
                                        size: 24),
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Сфотографировать',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMd),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Gallery button
                              SizedBox(
                                width: 58,
                                height: 64,
                                child: ElevatedButton(
                                  onPressed: isUploading || isRecognizingQuick
                                      ? null
                                      : () async {
                                          await pickImages(ctx, setModalState);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: palette.surface2,
                                    foregroundColor: palette.onSurface2,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusMd),
                                      side:
                                          BorderSide(color: palette.cardBorder),
                                    ),
                                  ),
                                  child: const Icon(Icons.photo_library_rounded,
                                      size: 24),
                                ),
                              ),
                            ],
                          ),
                          if (pickedImagePaths.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: pickedImagePaths.length,
                                itemBuilder: (ctx, idx) {
                                  final path = pickedImagePaths[idx];
                                  return Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                AppTheme.radiusSm),
                                            child: Image.file(
                                              File(path),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () {
                                              safeSetModalState(() {
                                                pickedImagePaths.removeAt(idx);
                                              });
                                            },
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Text field
                          TextField(
                            controller: quickCommandController,
                            minLines: 2,
                            maxLines: 4,
                            style: TextStyle(color: palette.onBg, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Уточните задание',
                              hintStyle: TextStyle(
                                color:
                                    palette.onSurface3.withValues(alpha: 0.8),
                              ),
                              filled: true,
                              fillColor: fieldSurface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusLg),
                                borderSide:
                                    BorderSide(color: palette.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusLg),
                                borderSide:
                                    BorderSide(color: palette.cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusLg),
                                borderSide:
                                    const BorderSide(color: AppTheme.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // "Publish" button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: isUploading || isRecognizingQuick
                                  ? null
                                  : () async {
                                      await recognizeQuickHomework(
                                          ctx, setModalState);
                                    },
                              icon: isRecognizingQuick
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome_rounded),
                              label: Text(
                                isRecognizingQuick
                                    ? 'Публикуем...'
                                    : 'Опубликовать',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryDim,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // "Add manually" link
                          Center(
                            child: TextButton(
                              onPressed: () {
                                safeSetModalState(() {
                                  isQuickMode = false;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Добавить вручную',
                                style: TextStyle(
                                  color: palette.onSurface3,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],

                        if (!isQuickMode) ...[
                          if (quickRecognitionMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: modalSurface,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: palette.cardBorder),
                              ),
                              child: Text(
                                quickRecognitionMessage!,
                                style: TextStyle(
                                  color: palette.onBg,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                          // Subject
                          formLabel('Предмет'),
                          const SizedBox(height: 6),
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: fieldSurface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: palette.cardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedSubject,
                                hint: Text('Выберите предмет',
                                    style: TextStyle(
                                        color: palette.onSurface3
                                            .withValues(alpha: 0.8),
                                        fontSize: 14)),
                                isExpanded: true,
                                dropdownColor: fieldSurface,
                                style: TextStyle(
                                      color: palette.onBg, fontSize: 14),
                                items: allSubjects
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) => safeSetModalState(
                                    () => selectedSubject = v),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (selectedSubject == 'Геометрия' || selectedSubject == 'Алгебра') ...[
                            GestureDetector(
                              onTap: () => safeSetModalState(
                                  () => isTextbookGeometry = !isTextbookGeometry),
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: isTextbookGeometry,
                                      onChanged: (v) => safeSetModalState(
                                          () => isTextbookGeometry = v ?? false),
                                      activeColor: AppTheme.primary,
                                      side: BorderSide(color: palette.onSurface3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Прикрепить ответы из учебника',
                                      style: TextStyle(
                                          color: palette.onBg, fontSize: 14)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Task
                          formLabel('Задание'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: taskController,
                            maxLines: 4,
                            style: TextStyle(color: palette.onBg, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Опишите задание...',
                              hintStyle: TextStyle(
                                  color: palette.onSurface3
                                      .withValues(alpha: 0.8)),
                              filled: true,
                              fillColor: fieldSurface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                borderSide:
                                    BorderSide(color: palette.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                borderSide:
                                    BorderSide(color: palette.cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                borderSide:
                                    const BorderSide(color: AppTheme.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Photo picker
                          formLabel('Фото (необязательно)'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              await pickImages(ctx, setModalState);
                            },
                            child: Container(
                              width: double.infinity,
                              height: pickedImagePaths.isEmpty ? 50 : 170,
                              decoration: BoxDecoration(
                                color: fieldSurface,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: palette.cardBorder),
                              ),
                              child: pickedImagePaths.isEmpty
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.photo_library_rounded,
                                            color: palette.onSurface3
                                                .withValues(alpha: 0.8),
                                            size: 22),
                                        const SizedBox(width: 8),
                                        Text('Добавить фото',
                                            style: TextStyle(
                                                color: palette.onSurface3
                                                    .withValues(alpha: 0.8),
                                                fontSize: 14)),
                                      ],
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.all(8),
                                      itemCount: pickedImagePaths.length + 1,
                                      itemBuilder: (ctx, idx) {
                                        if (idx == pickedImagePaths.length) {
                                          return GestureDetector(
                                            onTap: () async {
                                              await pickImages(
                                                  ctx, setModalState);
                                            },
                                            child: Container(
                                              width: 120,
                                              margin: const EdgeInsets.only(
                                                  left: 8),
                                              decoration: BoxDecoration(
                                                color: modalSurface,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppTheme.radiusSm),
                                                border: Border.all(
                                                    color: palette.cardBorder),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                    Icons.add_a_photo_rounded,
                                                    color: AppTheme.primaryDim),
                                              ),
                                            ),
                                          );
                                        }
                                        final path = pickedImagePaths[idx];
                                        return Container(
                                          width: 120,
                                          margin: EdgeInsets.only(
                                              right: idx ==
                                                      pickedImagePaths.length -
                                                          1
                                                  ? 0
                                                  : 8),
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppTheme.radiusSm),
                                                  child: Image.file(
                                                    File(path),
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (ctx, err, stack) =>
                                                            Container(
                                                      color: palette.surface2,
                                                      alignment:
                                                          Alignment.center,
                                                      child: const Icon(
                                                        Icons
                                                            .broken_image_rounded,
                                                        color: Colors.white70,
                                                        size: 24,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    safeSetModalState(() {
                                                      pickedImagePaths
                                                          .removeAt(idx);
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.black54,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    child: const Icon(
                                                        Icons.close_rounded,
                                                        color: Colors.white,
                                                        size: 14),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Deadline
                          formLabel('Срок сдачи'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                locale: const Locale('ru', 'RU'),
                                initialDate: selectedDeadline,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                                selectableDayPredicate: (DateTime val) =>
                                    val.weekday != 6 && val.weekday != 7,
                                builder: (context, child) {
                                  final pickerBaseTheme = Theme.of(context);
                                  return Theme(
                                    data: pickerBaseTheme.copyWith(
                                      colorScheme:
                                          pickerBaseTheme.colorScheme.copyWith(
                                        primary: AppTheme.primary,
                                        onPrimary: Colors.white,
                                        surface: palette.surface2,
                                        onSurface: palette.onBg,
                                      ),
                                      dialogTheme: DialogThemeData(
                                        backgroundColor: palette.surface2,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                safeSetModalState(
                                    () => selectedDeadline = picked);
                              }
                            },
                            child: Container(
                              height: 44,
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: fieldSurface,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: palette.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 18, color: palette.onSurface2),
                                  const SizedBox(width: 10),
                                  Text(
                                    date_utils.formatDate(selectedDeadline),
                                    style: TextStyle(
                                        color: palette.onBg, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isUploading
                                  ? null
                                  : () async {
                                      await doSubmit(
                                        safeSetModalState: safeSetModalState,
                                        sheetContext: ctx,
                                      );
                                    },
                              child: isUploading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text('Сохранить задание'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
  taskController.dispose();
  quickCommandController.dispose();
}
