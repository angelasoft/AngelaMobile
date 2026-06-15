import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/agreement_documents.dart';

/// 약관 내용을 바텀시트로 표시한다.
Future<void> showAgreementSheet(BuildContext context, AgreementType type) {
  final document = AgreementDocument.of(type);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.shadow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.title,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.subtitle,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.shadow.withValues(alpha: 0.08)),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Text(
                    document.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.title.withValues(alpha: 0.85),
                          height: 1.7,
                        ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
