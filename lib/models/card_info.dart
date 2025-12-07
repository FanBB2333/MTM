import 'dart:typed_data';

/// NFC卡片信息数据模型
class CardInfo {
  /// 卡片UID
  final Uint8List uid;
  
  /// ATQA (Answer To Request, Type A)
  final Uint8List atqa;
  
  /// SAK (Select Acknowledge)
  final int sak;
  
  /// 卡片类型描述
  final String cardType;

  CardInfo({
    required this.uid,
    required this.atqa,
    required this.sak,
  }) : cardType = _getCardType(sak);

  /// 格式化UID为十六进制字符串 (如 "3A:0B:20:9A")
  String get uidHex {
    return uid.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
  }

  /// 格式化ATQA为十六进制字符串
  String get atqaHex {
    return atqa.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join('');
  }

  /// 格式化SAK为十六进制字符串
  String get sakHex {
    return '0x${sak.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  /// 根据SAK判断卡片类型
  static String _getCardType(int sak) {
    const cardTypes = {
      0x08: 'Mifare Classic 1K',
      0x18: 'Mifare Classic 4K',
      0x00: 'Mifare Ultralight / NTAG',
      0x09: 'Mifare Mini',
      0x10: 'Mifare Plus 2K',
      0x11: 'Mifare Plus 4K',
      0x20: 'Mifare Plus / DESFire / JCOP',
      0x28: 'SmartMX with Mifare 1K',
      0x38: 'SmartMX with Mifare 4K',
    };
    return cardTypes[sak] ?? 'Unknown (SAK=0x${sak.toRadixString(16).toUpperCase()})';
  }

  /// 是否是Mifare Classic卡片
  bool get isMifareClassic => sak == 0x08 || sak == 0x18;

  @override
  String toString() {
    return 'CardInfo(uid: $uidHex, atqa: $atqaHex, sak: $sakHex, type: $cardType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CardInfo) return false;
    if (uid.length != other.uid.length) return false;
    for (int i = 0; i < uid.length; i++) {
      if (uid[i] != other.uid[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(uid);
}

/// 串口设备信息
class SerialDeviceInfo {
  final String port;
  final String description;
  final String? manufacturer;
  final String? serialNumber;

  SerialDeviceInfo({
    required this.port,
    required this.description,
    this.manufacturer,
    this.serialNumber,
  });

  @override
  String toString() => 'SerialDeviceInfo(port: $port, description: $description)';
}
