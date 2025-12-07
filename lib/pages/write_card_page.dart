import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/card_dump.dart';
import '../services/card_file_service.dart';
import '../services/pn532_service.dart';

/// 写卡页面
class WriteCardPage extends StatefulWidget {
  const WriteCardPage({super.key});

  @override
  State<WriteCardPage> createState() => _WriteCardPageState();
}

class _WriteCardPageState extends State<WriteCardPage> {
  final _pn532Service = PN532Service.instance;
  
  String _dataSource = 'file';  // file, clone
  bool _writeBlock0 = false;
  bool _isWriting = false;
  double _progress = 0;
  
  // 已加载的数据
  CardDump? _loadedDump;
  String? _loadedFileName;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isConnected = _pn532Service.isConnected;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 64,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // 标题
                Text(
                  l10n.writeCardTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isConnected 
                      ? l10n.writeCardSubtitle
                      : l10n.readCardNotConnected,
                  style: TextStyle(
                    fontSize: 14,
                    color: isConnected ? AppColors.textSecondary : AppColors.warning,
                  ),
                ),
                
                const SizedBox(height: 32),

                // 数据源选择
                _buildSourceSection(l10n),
                
                // 已加载文件预览
                if (_loadedDump != null) ...[
                  const SizedBox(height: 24),
                  _buildLoadedDataPreview(l10n),
                ],
                
                // 错误信息
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(),
                ],
                
                const SizedBox(height: 24),
                
                // 高级选项
                _buildOptionsSection(l10n),
                
                const SizedBox(height: 32),
                
                // 写入按钮
                _buildWriteButton(l10n),
                
                const SizedBox(height: 24),
                
                // 进度显示
                if (_isWriting) _buildProgress(l10n),
                
                const SizedBox(height: 24),
                
                // 警告信息
                _buildWarning(l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dataSource,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildSourceCard(
          l10n.loadFromFile,
          _loadedFileName ?? l10n.selectDumpFile,
          CupertinoIcons.folder_open,
          'file',
          onTap: _loadFromFile,
        ),
        const SizedBox(height: 12),
        _buildSourceCard(
          l10n.cloneFromReader,
          l10n.useLastReadData,
          CupertinoIcons.doc_on_clipboard,
          'clone',
        ),
      ],
    );
  }

  Widget _buildSourceCard(String title, String subtitle, IconData icon, String value, {VoidCallback? onTap}) {
    final isSelected = _dataSource == value;
    return GestureDetector(
      onTap: () {
        setState(() => _dataSource = value);
        if (value == 'file' && onTap != null) {
          onTap();
        }
      },
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
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildLoadedDataPreview(AppLocalizations l10n) {
    final dump = _loadedDump!;
    final sectorCount = dump.sectorData.length;
    final validSectors = dump.sectorData.values.where((blocks) => 
        blocks.any((b) => b != null && b.any((byte) => byte != 0))
    ).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.loadedFromFile,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dump.cardInfo != null) ...[
            _buildPreviewRow('UID', dump.cardInfo!.uidHex),
            _buildPreviewRow('Type', dump.cardInfo!.cardType),
          ],
          _buildPreviewRow('Sectors', '$validSectors / $sectorCount'),
          _buildPreviewRow('Size', '${dump.totalBytes} bytes'),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: AppColors.textPrimary,
            ),
          ),
        ],
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

  Widget _buildOptionsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.options,
          style: const TextStyle(
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
              Text(
                l10n.writeBlock0,
                style: const TextStyle(fontSize: 14),
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

  Widget _buildWriteButton(AppLocalizations l10n) {
    final canWrite = _pn532Service.isConnected && 
        ((_dataSource == 'file' && _loadedDump != null) || _dataSource == 'clone');
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_isWriting || !canWrite) ? null : _startWriting,
        icon: _isWriting
            ? const CupertinoActivityIndicator(radius: 10)
            : const Icon(CupertinoIcons.pencil),
        label: Text(_isWriting ? l10n.writing : l10n.startWriting),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildProgress(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.writingSectors,
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

  Widget _buildWarning(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(75)),
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
              l10n.writeBlock0Warning,
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

  Future<void> _loadFromFile() async {
    final l10n = AppLocalizations.of(context);
    
    try {
      setState(() => _errorMessage = null);
      
      final dump = await CardFileService.instance.loadCardDump();
      
      if (dump != null) {
        setState(() {
          _loadedDump = dump;
          _loadedFileName = 'Loaded ${dump.totalBytes} bytes';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${l10n.fileLoadError}: $e';
        _loadedDump = null;
        _loadedFileName = null;
      });
    }
  }

  Future<void> _startWriting() async {
    final l10n = AppLocalizations.of(context);
    
    if (_dataSource == 'file' && _loadedDump == null) {
      setState(() => _errorMessage = 'Please load a dump file first.');
      return;
    }
    
    setState(() {
      _isWriting = true;
      _progress = 0;
      _errorMessage = null;
    });
    
    try {
      // 读取目标卡片
      final targetCard = await _pn532Service.readCard();
      if (targetCard == null) {
        setState(() {
          _errorMessage = 'No card detected. Please place a card on the reader.';
          _isWriting = false;
        });
        return;
      }
      
      final dump = _loadedDump!;
      final sectorCount = dump.sectorCount;
      int writtenSectors = 0;
      
      // 默认密钥
      final defaultKey = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);
      
      for (int sector = 0; sector < sectorCount; sector++) {
        final blocks = dump.sectorData[sector];
        if (blocks == null) continue;
        
        final firstBlock = sector * 4;
        
        // 认证
        bool authed = await _pn532Service.mifareAuth(
          firstBlock, 
          targetCard.uid, 
          key: defaultKey,
          keyType: 'A',
        );
        
        if (!authed) {
          authed = await _pn532Service.mifareAuth(
            firstBlock, 
            targetCard.uid, 
            key: defaultKey,
            keyType: 'B',
          );
        }
        
        if (!authed) {
          // 跳过无法认证的扇区
          continue;
        }
        
        // 写入块 (跳过 block 0 除非明确选择)
        for (int i = 0; i < blocks.length; i++) {
          final blockNum = firstBlock + i;
          
          // 跳过 block 0 (UID block) 除非用户选择写入
          if (blockNum == 0 && !_writeBlock0) continue;
          
          // 跳过 trailer block (每个扇区最后一块包含密钥)
          if (i == 3) continue;
          
          final blockData = blocks[i];
          if (blockData != null && blockData.length == 16) {
            await _pn532Service.mifareWriteBlock(blockNum, blockData);
          }
        }
        
        writtenSectors++;
        setState(() => _progress = writtenSectors / sectorCount);
      }
      
      setState(() => _isWriting = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.writeCompleted),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Write error: $e';
        _isWriting = false;
      });
    }
  }
}
