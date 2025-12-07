import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

/// 写卡页面
class WriteCardPage extends StatefulWidget {
  const WriteCardPage({super.key});

  @override
  State<WriteCardPage> createState() => _WriteCardPageState();
}

class _WriteCardPageState extends State<WriteCardPage> {
  String _dataSource = 'file';  // file, clone
  bool _writeBlock0 = false;
  bool _isWriting = false;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          const Text(
            'Write Card',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Write data to blank or UID cards',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),

          // 数据源选择
          _buildSourceSection(),
          
          const SizedBox(height: 24),
          
          // 高级选项
          _buildOptionsSection(),
          
          const SizedBox(height: 32),
          
          // 写入按钮
          _buildWriteButton(),
          
          const SizedBox(height: 24),
          
          // 进度显示
          if (_isWriting) _buildProgress(),
          
          const Spacer(),
          
          // 警告信息
          _buildWarning(),
        ],
      ),
    );
  }

  Widget _buildSourceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Source',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildSourceCard(
          'Load from File',
          'Select a .mfc or .bin dump file',
          CupertinoIcons.folder_open,
          'file',
        ),
        const SizedBox(height: 12),
        _buildSourceCard(
          'Clone from Reader',
          'Use the last read card data',
          CupertinoIcons.doc_on_clipboard,
          'clone',
        ),
      ],
    );
  }

  Widget _buildSourceCard(String title, String subtitle, IconData icon, String value) {
    final isSelected = _dataSource == value;
    return GestureDetector(
      onTap: () => setState(() => _dataSource = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.iconActive : AppColors.iconInactive,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: AppColors.iconActive,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Write Block 0 (UID)',
                style: TextStyle(fontSize: 14),
              ),
              CupertinoSwitch(
                value: _writeBlock0,
                onChanged: (v) => setState(() => _writeBlock0 = v),
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWriteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isWriting ? null : _startWriting,
        icon: _isWriting
            ? const CupertinoActivityIndicator(radius: 10)
            : const Icon(CupertinoIcons.pencil),
        label: Text(_isWriting ? 'Writing...' : 'Start Writing'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Writing sectors...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(AppColors.success),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Writing Block 0 requires a UID/CUID magic card. Standard cards do not support this.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startWriting() async {
    setState(() {
      _isWriting = true;
      _progress = 0;
    });
    
    // 模拟写入进度
    for (int i = 0; i <= 16; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => _progress = i / 16);
    }
    
    setState(() => _isWriting = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Write completed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
