import 'dart:typed_data';
import 'card_info.dart';

/// Mifare Classic 卡片转储数据模型
/// 支持标准 .mfc 格式 (1024 bytes for 1K, 4096 bytes for 4K)
class CardDump {
  /// 卡片信息
  final CardInfo? cardInfo;
  
  /// 扇区数据 Map<扇区号, List<块数据>>
  final Map<int, List<Uint8List?>> sectorData;
  
  /// 卡片类型: 1 = 1K (16 sectors), 4 = 4K (40 sectors)
  final int cardType;

  CardDump({
    this.cardInfo,
    required this.sectorData,
    this.cardType = 1,
  });

  /// 获取扇区数量
  int get sectorCount => cardType == 4 ? 40 : 16;
  
  /// 获取总字节数
  int get totalBytes => cardType == 4 ? 4096 : 1024;

  /// 序列化为标准 .mfc 格式字节数组
  /// 每个块 16 bytes，每个扇区 4 块 (1K) 或更多 (4K 后半部分)
  Uint8List toBytes() {
    final bytes = Uint8List(totalBytes);
    int offset = 0;
    
    for (int sector = 0; sector < sectorCount; sector++) {
      final blocksInSector = sector < 32 ? 4 : 16; // 4K 后 8 个扇区每个有 16 块
      final blocks = sectorData[sector] ?? [];
      
      for (int block = 0; block < blocksInSector; block++) {
        final blockData = blocks.length > block ? blocks[block] : null;
        
        if (blockData != null && blockData.length == 16) {
          bytes.setRange(offset, offset + 16, blockData);
        } else {
          // 无数据的块填充 0x00
          for (int i = 0; i < 16; i++) {
            bytes[offset + i] = 0x00;
          }
        }
        offset += 16;
      }
    }
    
    return bytes;
  }

  /// 从 .mfc 格式字节数组解析
  factory CardDump.fromBytes(Uint8List bytes) {
    final cardType = bytes.length >= 4096 ? 4 : 1;
    final sectorCount = cardType == 4 ? 40 : 16;
    final sectorData = <int, List<Uint8List?>>{};
    
    int offset = 0;
    
    for (int sector = 0; sector < sectorCount; sector++) {
      final blocksInSector = sector < 32 ? 4 : 16;
      final blocks = <Uint8List?>[];
      
      for (int block = 0; block < blocksInSector; block++) {
        if (offset + 16 <= bytes.length) {
          blocks.add(Uint8List.fromList(bytes.sublist(offset, offset + 16)));
        } else {
          blocks.add(null);
        }
        offset += 16;
      }
      
      sectorData[sector] = blocks;
    }
    
    // 尝试从块 0 提取 UID (前 4 或 7 字节)
    CardInfo? cardInfo;
    if (sectorData[0] != null && sectorData[0]!.isNotEmpty && sectorData[0]![0] != null) {
      final block0 = sectorData[0]![0]!;
      // 简单假设 4 字节 UID
      final uid = Uint8List.fromList(block0.sublist(0, 4));
      // SAK 和 ATQA 无法从 dump 中获取，使用默认值
      cardInfo = CardInfo(
        uid: uid,
        atqa: Uint8List.fromList([0x00, 0x04]),
        sak: cardType == 4 ? 0x18 : 0x08,
      );
    }
    
    return CardDump(
      cardInfo: cardInfo,
      sectorData: sectorData,
      cardType: cardType,
    );
  }

  /// 从 ReadCardPage 读取的数据创建 CardDump
  factory CardDump.fromReadData({
    CardInfo? cardInfo,
    required Map<int, List<Uint8List?>> sectorData,
  }) {
    // 根据数据推断卡类型
    final maxSector = sectorData.keys.reduce((a, b) => a > b ? a : b);
    final cardType = maxSector >= 16 ? 4 : 1;
    
    return CardDump(
      cardInfo: cardInfo,
      sectorData: sectorData,
      cardType: cardType,
    );
  }
}
