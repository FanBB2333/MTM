import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

/// 卡包页面 - 管理已保存的卡片数据
class SavedCardsPage extends StatelessWidget {
  const SavedCardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // 模拟数据
    final savedCards = <Map<String, String>>[];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.savedCardsTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              // 导入按钮
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(CupertinoIcons.folder_badge_plus, size: 18),
                label: const Text('Import'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.savedCardsSubtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 卡片列表
          Expanded(
            child: savedCards.isEmpty
                ? _buildEmptyState(l10n)
                : _buildCardGrid(savedCards),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.folder,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noSavedCards,
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.saveCardsHint,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid(List<Map<String, String>> cards) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _SavedCardTile(
          name: card['name'] ?? '',
          type: card['type'] ?? '',
          date: card['date'] ?? '',
        );
      },
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  final String name;
  final String type;
  final String date;

  const _SavedCardTile({
    required this.name,
    required this.type,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          hoverColor: AppColors.primaryLight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.creditcard,
                        size: 20,
                        color: AppColors.iconActive,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton(
                      icon: Icon(
                        CupertinoIcons.ellipsis,
                        color: AppColors.iconInactive,
                        size: 18,
                      ),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'write',
                          child: Text('Write to Card'),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Text('Export'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$type • $date',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
