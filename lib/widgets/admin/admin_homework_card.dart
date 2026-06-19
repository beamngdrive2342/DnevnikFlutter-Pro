import 'package:flutter/material.dart';
import '../../data/schedule_data.dart';
import '../../theme/app_theme.dart';
import '../network_photo.dart';

class AdminHomeworkCard extends StatelessWidget {
  final HomeworkItem hw;
  final List<String> images;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminHomeworkCard({
    super.key,
    required this.hw,
    required this.images,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border.all(color: palette.cardBorder),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    hw.subject,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDim,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  hw.deadline,
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.onSurface2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...images.map((url) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: NetworkPhoto(
                      url: url,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loading: Container(
                        height: 150,
                        color: palette.surface3,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      error: Container(
                        height: 150,
                        color: palette.surface3,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: palette.onSurface3,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
            Text(
              hw.task,
              style: TextStyle(fontSize: 14, color: palette.onBg, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Ред.', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  label: const Text('Удалить', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
