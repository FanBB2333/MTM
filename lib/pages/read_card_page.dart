import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../services/pn532_service.dart';
import '../models/card_info.dart';
import '../l10n/app_localizations.dart';

/// 读卡页面
class ReadCardPage extends StatefulWidget {
  const ReadCardPage({super.key});

  @override
  State<ReadCardPage> createState() => _ReadCardPageState();
}

class _ReadCardPageState extends State<ReadCardPage> {
  final _pn532Service = PN532Service.instance;
  
  String _readMode = 'full';  // full, sector, block
  final _keyAController = TextEditingController(text: 'FFFFFFFFFFFF');
  final _keyBController = TextEditingController(text: 'FFFFFFFFFFFF');
  final _sectorController = TextEditingController(text: '0');
  final _blockController = TextEditingController(text: '0');
  
  bool _isReading = false;
  CardInfo? _currentCard;
  Map<int, List<Uint8List?>>? _sectorData;
  Uint8List? _blockData;
  String? _errorMessage;

  @override
  void dispose() {
    _keyAController.dispose();
    _keyBController.dispose();
    _sectorController.dispose();
    _blockController.dispose();
    super.dispose();
  }

  Uint8List? _parseKey(String hex) {
    try {
      hex = hex.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
      if (hex.length != 12) return null;
      
      final bytes = <int>[];
      for (int i = 0; i < 12; i += 2) {
        bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
      }
      return Uint8List.fromList(bytes);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _pn532Service.isConnected;
    final l10n = AppLocalizations.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            l10n.readCardTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isConnected 
                ? l10n.readCardSubtitle
                : l10n.readCardNotConnected,
            style: TextStyle(
              fontSize: 14,
              color: isConnected ? AppColors.textSecondary : AppColors.warning,
            ),
          ),
          
          const SizedBox(height: 32),

          if (!isConnected)
            _buildNotConnectedWarning(l10n)
          else ...[
            // 读取模式选择
            _buildModeSection(l10n),
            
            const SizedBox(height: 24),
            
            // 密钥输入
            _buildKeySection(l10n),
            
            const SizedBox(height: 32),
            
            // 读取按钮
            _buildReadButton(l10n),
            
            // 错误信息
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(),
            ],
            
            const SizedBox(height: 24),
            
            // 数据展示区
            Expanded(
              child: _buildDataView(l10n),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotConnectedWarning(AppLocalizations l10n) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.pn532NotConnected,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.goToConnectPage,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.readMode,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildModeChip(l10n.fullCard, 'full'),
            const SizedBox(width: 12),
            _buildModeChip(l10n.sector, 'sector'),
            const SizedBox(width: 12),
            _buildModeChip(l10n.block, 'block'),
          ],
        ),
        // 额外参数输入
        if (_readMode == 'sector') ...[
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _sectorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sector (0-15)',
                isDense: true,
              ),
            ),
          ),
        ],
        if (_readMode == 'block') ...[
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _blockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Block (0-63)',
                isDense: true,
              ),
            ),
          ),
        ],
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

  Widget _buildKeySection(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildKeyInput(l10n.keyA, _keyAController),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKeyInput(l10n.keyB, _keyBController),
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

  Widget _buildReadButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isReading ? null : _startReading,
        icon: _isReading
            ? const CupertinoActivityIndicator(radius: 10)
            : const Icon(CupertinoIcons.creditcard),
        label: Text(_isReading ? l10n.reading : l10n.startReading),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withAlpha(75)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.exclamationmark_circle, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataView(AppLocalizations l10n) {
    if (_currentCard == null && _sectorData == null && _blockData == null) {
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
              l10n.placeCardOnReader,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片信息
          if (_currentCard != null) ...[
            _buildCardInfoSection(),
            const SizedBox(height: 24),
          ],
          
          // 扇区数据
          if (_sectorData != null) _buildSectorDataView(),
          
          // 单块数据
          if (_blockData != null) _buildBlockDataView(),
        ],
      ),
    );
  }

  Widget _buildCardInfoSection() {
    final card = _currentCard!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Card Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('UID', card.uidHex),
          _buildInfoRow('ATQA', card.atqaHex),
          _buildInfoRow('SAK', card.sakHex),
          _buildInfoRow('Type', card.cardType),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorDataView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sector Data',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...(_sectorData!.entries.map((entry) {
          final sector = entry.key;
          final blocks = entry.value;
          return _buildSectorBlock(sector, blocks);
        })),
      ],
    );
  }

  Widget _buildSectorBlock(int sector, List<Uint8List?> blocks) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sector $sector',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(4, (i) {
            final data = blocks.length > i ? blocks[i] : null;
            return _buildBlockRow(i, data, isTrailer: i == 3);
          }),
        ],
      ),
    );
  }

  Widget _buildBlockRow(int blockNum, Uint8List? data, {bool isTrailer = false}) {
    final hexString = data != null
        ? data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')
        : '-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'B$blockNum',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: isTrailer ? AppColors.warning : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              hexString,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: data != null ? AppColors.textPrimary : AppColors.textDisabled,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockDataView() {
    final hexString = _blockData!
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Block ${_blockController.text}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hexString,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startReading() async {
    setState(() {
      _isReading = true;
      _errorMessage = null;
      _sectorData = null;
      _blockData = null;
    });
    
    try {
      // 读取卡片
      final card = await _pn532Service.readCard();
      
      if (card == null) {
        setState(() {
          _errorMessage = 'No card detected. Please place a card on the reader.';
          _isReading = false;
        });
        return;
      }
      
      setState(() => _currentCard = card);
      
      // 解析密钥
      final keyA = _parseKey(_keyAController.text);
      final keyB = _parseKey(_keyBController.text);
      
      if (!card.isMifareClassic) {
        setState(() {
          _errorMessage = 'This card type does not support Mifare Classic read operations.';
          _isReading = false;
        });
        return;
      }
      
      switch (_readMode) {
        case 'full':
          // 读取全部扇区
          final data = await _pn532Service.readMifareSectors(
            uid: card.uid,
            keyA: keyA,
            keyB: keyB,
            sectors: card.sak == 0x18 ? 40 : 16,
          );
          setState(() => _sectorData = data);
          break;
          
        case 'sector':
          // 读取单个扇区
          final sector = int.tryParse(_sectorController.text) ?? 0;
          final data = await _pn532Service.readMifareSectors(
            uid: card.uid,
            keyA: keyA,
            keyB: keyB,
            sectors: sector + 1,
          );
          setState(() => _sectorData = {sector: data[sector] ?? []});
          break;
          
        case 'block':
          // 读取单个块
          final block = int.tryParse(_blockController.text) ?? 0;
          final sector = block ~/ 4;
          
          // 先认证
          final authed = await _pn532Service.mifareAuth(
            sector * 4,
            card.uid,
            key: keyA,
            keyType: 'A',
          );
          
          if (!authed) {
            setState(() {
              _errorMessage = 'Authentication failed for block $block';
              _isReading = false;
            });
            return;
          }
          
          // 读取块
          final blockData = await _pn532Service.mifareReadBlock(block);
          setState(() => _blockData = blockData);
          break;
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isReading = false);
    }
  }
}
