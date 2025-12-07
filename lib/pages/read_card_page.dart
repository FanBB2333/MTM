import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

/// 读卡页面
class ReadCardPage extends StatefulWidget {
  const ReadCardPage({super.key});

  @override
  State<ReadCardPage> createState() => _ReadCardPageState();
}

class _ReadCardPageState extends State<ReadCardPage> {
  String _readMode = 'full';  // full, sector, block
  final _keyAController = TextEditingController(text: 'FFFFFFFFFFFF');
  final _keyBController = TextEditingController(text: 'FFFFFFFFFFFF');
  bool _isReading = false;
  String? _cardData;

  @override
  void dispose() {
    _keyAController.dispose();
    _keyBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          const Text(
            'Read Card',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Read data from NFC cards (Mifare Classic 1K/4K)',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),

          // 读取模式选择
          _buildModeSection(),
          
          const SizedBox(height: 24),
          
          // 密钥输入
          _buildKeySection(),
          
          const SizedBox(height: 32),
          
          // 读取按钮
          _buildReadButton(),
          
          const SizedBox(height: 24),
          
          // 数据展示区
          Expanded(
            child: _buildDataView(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Read Mode',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildModeChip('Full Card', 'full'),
            const SizedBox(width: 12),
            _buildModeChip('Sector', 'sector'),
            const SizedBox(width: 12),
            _buildModeChip('Block', 'block'),
          ],
        ),
      ],
    );
  }

  Widget _buildModeChip(String label, String value) {
    final isSelected = _readMode == value;
    return GestureDetector(
      onTap: () => setState(() => _readMode = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildKeySection() {
    return Row(
      children: [
        Expanded(
          child: _buildKeyInput('Key A', _keyAController),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKeyInput('Key B', _keyBController),
        ),
      ],
    );
  }

  Widget _buildKeyInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'FFFFFFFFFFFF',
            hintStyle: TextStyle(
              color: AppColors.textDisabled,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isReading ? null : _startReading,
        icon: _isReading
            ? const CupertinoActivityIndicator(radius: 10)
            : const Icon(CupertinoIcons.creditcard),
        label: Text(_isReading ? 'Reading...' : 'Start Reading'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDataView() {
    if (_cardData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.creditcard,
              size: 48,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'Place card on reader and press Start',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: SingleChildScrollView(
        child: Text(
          _cardData!,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _startReading() async {
    setState(() => _isReading = true);
    
    // 模拟读卡
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isReading = false;
      _cardData = '''Sector 0:
  Block 0: 3A 0B 20 9A 00 08 04 00 62 63 64 65 66 67 68 69
  Block 1: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  Block 2: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  Block 3: FF FF FF FF FF FF FF 07 80 69 FF FF FF FF FF FF

Sector 1:
  Block 4: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  Block 5: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  ...''';
    });
  }
}
