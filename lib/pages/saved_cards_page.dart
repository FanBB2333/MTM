import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

/// 卡包页面 - 管理已保存的卡片数据
class SavedCardsPage extends StatelessWidget {
  const SavedCardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 模拟数据
    final savedCards = [
      {'name': 'Home Key', 'type': 'Mifare 1K', 'date': '2024-12-06'},
      {'name': 'Office Card', 'type': 'Mifare 1K', 'date': '2024-12-05'},
      {'name': 'Backup #1', 'type': 'Mifare 4K', 'date': '2024-12-01'},
    ];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saved Cards',
                style: TextStyle(
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
            'Manage your saved dump files (.mfc, .bin)',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 卡片列表
          Expanded(
            child: savedCards.isEmpty
                ? _buildEmptyState()
                : _buildCardGrid(savedCards),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No saved cards yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Read a card and save it to see it here',
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
