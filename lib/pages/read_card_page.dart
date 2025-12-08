import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../services/pn532_service.dart';
import '../services/card_file_service.dart';
import '../services/crack_service.dart';
import '../models/card_info.dart';
import '../models/card_dump.dart';
import '../l10n/app_localizations.dart';
import '../widgets/terminal_output.dart';

/// 读卡页面
class ReadCardPage extends StatefulWidget {
  const ReadCardPage({super.key});

  @override
  State<ReadCardPage> createState() => _ReadCardPageState();
}

class _ReadCardPageState extends State<ReadCardPage> {
  final _pn532Service = PN532Service.instance;
  final _crackService = CrackService.instance;
  
  String _readMode = 'full';  // full, sector, block
  // 默认密钥：全F
  final _keyListController = TextEditingController(text: 'FFFFFFFFFFFF');
  final _sectorController = TextEditingController(text: '0');
  final _blockController = TextEditingController(text: '0');
  
  bool _isReading = false;
  CardInfo? _currentCard;
  Map<int, List<Uint8List?>>? _sectorData;
  Uint8List? _blockData;
  String? _errorMessage;
  
  // Crack functionality
  bool _showTerminal = false;
  bool _isCracking = false;
  final GlobalKey<TerminalOutputState> _terminalKey = GlobalKey<TerminalOutputState>();
  StreamSubscription<String>? _outputSubscription;

  @override
  void dispose() {
    _keyListController.dispose();
    _sectorController.dispose();
    _blockController.dispose();
    _outputSubscription?.cancel();
    super.dispose();
  }

  /// 解析密钥列表
  List<Uint8List> _parseKeyList(String text) {
    final keys = <Uint8List>[];
    final lines = text.split('\n');
    
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      try {
        // 移除所有非十六进制字符
        final hex = line.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
        if (hex.length != 12) continue; // 忽略非12位密钥
        
        final bytes = <int>[];
        for (int i = 0; i < 12; i += 2) {
          bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
        }
        keys.add(Uint8List.fromList(bytes));
      } catch (e) {
        // 忽略解析错误
      }
    }
    
    // 如果没有有效密钥，添加默认密钥
    if (keys.isEmpty) {
      keys.add(Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]));
    }
    
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _pn532Service.isConnected;
    final l10n = AppLocalizations.of(context);
    
    return Row(
      children: [
        // 左侧面板 - 读卡界面
        Expanded(
          flex: _showTerminal ? 3 : 1,
          child: Padding(
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
          ),
        ),
        
        // 右侧面板 - 终端输出
        if (_showTerminal) ...[
          Container(width: 1, color: AppColors.divider),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TerminalOutput(
                key: _terminalKey,
                title: l10n.terminalOutput,
                outputStream: _crackService.outputStream,
                isRunning: _isCracking,
                onClose: () => setState(() => _showTerminal = false),
                onClear: () => _terminalKey.currentState?.clear(),
                onStop: _isCracking ? _stopCracking : null,
              ),
            ),
          ),
        ],
      ],
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildModeChip(l10n.fullCard, 'full'),
            _buildModeChip(l10n.sector, 'sector'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.keyList,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            // TODO: Load from file feature
            // TextButton.icon(
            //   onPressed: () {},
            //   icon: const Icon(CupertinoIcons.doc_text, size: 16),
            //   label: Text(l10n.loadKeysFromFile),
            // ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _keyListController,
          maxLines: 4,
          minLines: 2,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: l10n.keyListHint,
            hintStyle: TextStyle(
              color: AppColors.textDisabled,
              fontFamily: 'monospace',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            contentPadding: const EdgeInsets.all(12),
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
            child: SelectableText(
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

    return Column(
      children: [
        // 数据操作栏
        if (_sectorData != null || _blockData != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 破解按钮
                if (_currentCard != null) ...[
                  ElevatedButton.icon(
                    onPressed: _isCracking ? null : _crackWithMfoc,
                    icon: _isCracking 
                        ? const CupertinoActivityIndicator(radius: 8)
                        : const Icon(CupertinoIcons.lock_open, size: 16),
                    label: Text(l10n.crackWithMfoc),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isCracking ? null : _crackWithMfcuk,
                    icon: _isCracking 
                        ? const CupertinoActivityIndicator(radius: 8)
                        : const Icon(CupertinoIcons.lock_shield, size: 16),
                    label: Text(l10n.crackWithMfcuk),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
                ElevatedButton.icon(
                  onPressed: _saveToFile,
                  icon: const Icon(CupertinoIcons.square_arrow_down, size: 16),
                  label: Text(l10n.saveToFile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardBackground,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _copyAllData,
                  icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 16),
                  label: Text(l10n.copyAll),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardBackground,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          
        Expanded(
          child: SingleChildScrollView(
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
          ),
        ),
      ],
    );
  }

  void _copyAllData() {
    final buffer = StringBuffer();
    final l10n = AppLocalizations.of(context);
    
    if (_currentCard != null) {
      buffer.writeln('Card Info:');
      buffer.writeln('UID: ${_currentCard!.uidHex}');
      buffer.writeln('SAK: ${_currentCard!.sakHex}');
      buffer.writeln('ATQA: ${_currentCard!.atqaHex}');
      buffer.writeln('Type: ${_currentCard!.cardType}');
      buffer.writeln('');
    }
    
    if (_sectorData != null) {
      _sectorData!.forEach((sector, blocks) {
        buffer.writeln('Sector $sector:');
        for (int i = 0; i < blocks.length; i++) {
          final data = blocks[i];
          final hex = data != null 
              ? data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ') 
              : '-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --';
          buffer.writeln('  Block ${sector * 4 + i}: $hex');
        }
      });
    }
    
    if (_blockData != null) {
      final hex = _blockData!
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
      buffer.writeln('Block ${_blockController.text}: $hex');
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.dataCopied),
        behavior: SnackBarBehavior.floating,
        width: 300,
      ),
    );
  }

  Future<void> _saveToFile() async {
    final l10n = AppLocalizations.of(context);
    
    if (_sectorData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noDataToSave),
          behavior: SnackBarBehavior.floating,
          width: 300,
        ),
      );
      return;
    }
    
    try {
      // 创建 CardDump 对象
      final dump = CardDump.fromReadData(
        cardInfo: _currentCard,
        sectorData: _sectorData!,
      );
      
      // 生成文件名 (不包含扩展名，file_picker 会自动添加)
      final suggestedName = _currentCard != null 
          ? 'card_${_currentCard!.uidHex.replaceAll(':', '')}'
          : 'card_${DateTime.now().millisecondsSinceEpoch}';
      
      // 保存文件
      final path = await CardFileService.instance.saveCardDump(
        dump, 
        suggestedName: suggestedName,
      );
      
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fileSaved),
            behavior: SnackBarBehavior.floating,
            width: 300,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.fileSaveError}: $e'),
            behavior: SnackBarBehavior.floating,
            width: 400,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
            child: SelectableText(
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
            return _buildBlockRow(sector * 4 + i, data, isTrailer: i == 3);
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
            child: SelectableText(
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
          SelectableText(
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
      
      // 解析密钥列表
      final keys = _parseKeyList(_keyListController.text);
      
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
            keys: keys,
            sectors: card.sak == 0x18 ? 40 : 16,
          );
          setState(() => _sectorData = data);
          break;
          
        case 'sector':
          // 读取单个扇区
          final sector = int.tryParse(_sectorController.text) ?? 0;
          final data = await _pn532Service.readMifareSectors(
            uid: card.uid,
            keys: keys,
            sectors: sector + 1,
          );
          setState(() => _sectorData = {sector: data[sector] ?? []});
          break;
          
        case 'block':
          // 读取单个块
          final block = int.tryParse(_blockController.text) ?? 0;
          final sector = block ~/ 4;
          final firstBlock = sector * 4;
          
          bool authed = false;
          // 尝试所有密钥
          for (final key in keys) {
            authed = await _pn532Service.mifareAuth(
              firstBlock,
              card.uid,
              key: key,
              keyType: 'A',
            );
            if (!authed) {
              authed = await _pn532Service.mifareAuth(
                firstBlock,
                card.uid,
                key: key,
                keyType: 'B',
              );
            }
            if (authed) break;
          }
          
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

  /// 使用 mfoc 破解卡片
  Future<void> _crackWithMfoc() async {
    if (_currentCard == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noCardForCrack),
          behavior: SnackBarBehavior.floating,
          width: 300,
        ),
      );
      return;
    }

    setState(() {
      _showTerminal = true;
      _isCracking = true;
    });

    // 设置输出监听
    _outputSubscription?.cancel();
    _outputSubscription = _crackService.outputStream.listen((line) {
      _terminalKey.currentState?.addLine(line);
    });

    try {
      // 生成输出文件路径
      final tempDir = await getTemporaryDirectory();
      final uid = _currentCard!.uidHex.replaceAll(':', '');
      final outputPath = '${tempDir.path}/card_$uid.mfd';

      // 获取已知密钥（从输入框）
      final keys = _parseKeyList(_keyListController.text);
      final knownKeys = keys.map((k) => k.map((b) => b.toRadixString(16).padLeft(2, '0')).join()).toList();

      final success = await _crackService.runMfoc(
        outputPath: outputPath,
        knownKeys: knownKeys,
      );

      if (success && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.crackSuccess),
            behavior: SnackBarBehavior.floating,
            width: 300,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _terminalKey.currentState?.addLine('> Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isCracking = false);
      }
    }
  }

  /// 使用 mfcuk 破解卡片
  Future<void> _crackWithMfcuk() async {
    if (_currentCard == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noCardForCrack),
          behavior: SnackBarBehavior.floating,
          width: 300,
        ),
      );
      return;
    }

    setState(() {
      _showTerminal = true;
      _isCracking = true;
    });

    // 设置输出监听
    _outputSubscription?.cancel();
    _outputSubscription = _crackService.outputStream.listen((line) {
      _terminalKey.currentState?.addLine(line);
    });

    try {
      // 生成输出文件路径
      final tempDir = await getTemporaryDirectory();
      final uid = _currentCard!.uidHex.replaceAll(':', '');
      final outputPath = '${tempDir.path}/card_$uid.mfd';

      final success = await _crackService.runMfcuk(
        outputPath: outputPath,
      );

      if (success && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.crackSuccess),
            behavior: SnackBarBehavior.floating,
            width: 300,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _terminalKey.currentState?.addLine('> Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isCracking = false);
      }
    }
  }

  /// 停止破解进程
  void _stopCracking() {
    _crackService.stopProcess();
    setState(() => _isCracking = false);
  }
}

