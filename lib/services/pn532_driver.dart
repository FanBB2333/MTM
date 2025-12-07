import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';

/// PN532 NFC读卡器驱动类
/// 移植自Python版本的PN532驱动
class PN532Driver {
  // PN532 帧协议常量
  static const int preamble = 0x00;
  static const int startCode1 = 0x00;
  static const int startCode2 = 0xFF;
  static const int postamble = 0x00;
  static const int hostToPN532 = 0xD4;
  static const int pn532ToHost = 0xD5;

  // PN532 命令
  static const int cmdGetFirmwareVersion = 0x02;
  static const int cmdSamConfiguration = 0x14;
  static const int cmdInListPassiveTarget = 0x4A;
  static const int cmdInDataExchange = 0x40;

  // Mifare 命令
  static const int mifareAuthA = 0x60;
  static const int mifareAuthB = 0x61;
  static const int mifareRead = 0x30;
  static const int mifareWrite = 0xA0;

  // 默认密钥
  static final Uint8List defaultKey = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);

  final SerialPort _port;
  final SerialPortReader _reader;
  final bool debug;

  PN532Driver._(this._port, this._reader, {this.debug = false});

  /// 创建并初始化PN532驱动
  static Future<PN532Driver> open(String portName, {int baudRate = 115200, bool debug = false}) async {
    final port = SerialPort(portName);
    
    final config = SerialPortConfig()
      ..baudRate = baudRate
      ..bits = 8
      ..stopBits = 1
      ..parity = SerialPortParity.none
      ..setFlowControl(SerialPortFlowControl.none);
    
    if (!port.openReadWrite()) {
      throw Exception('无法打开串口 $portName: ${SerialPort.lastError}');
    }
    
    port.config = config;
    
    final reader = SerialPortReader(port, timeout: 1000);
    final driver = PN532Driver._(port, reader, debug: debug);
    
    // 唤醒设备
    await driver._wakeUp();
    
    return driver;
  }

  void _log(String msg) {
    if (debug) {
      print('[PN532] $msg');
    }
  }

  /// 唤醒PN532
  Future<void> _wakeUp() async {
    // 发送唤醒序列: 16个0x55 + 4个0x00
    final wakeup = Uint8List.fromList([
      ...List.filled(16, 0x55),
      ...List.filled(4, 0x00),
    ]);
    
    _port.write(wakeup);
    await Future.delayed(const Duration(milliseconds: 100));
    _port.flush();
    _log('唤醒序列已发送');
  }

  /// 构建数据帧
  Uint8List _buildFrame(List<int> data) {
    final length = data.length;
    final lcs = (~length + 1) & 0xFF;  // Length checksum

    final frame = <int>[
      preamble,
      startCode1,
      startCode2,
      length,
      lcs,
      ...data,
    ];

    // 计算数据校验和
    int dcs = 0;
    for (final byte in data) {
      dcs += byte;
    }
    dcs = (~dcs + 1) & 0xFF;
    
    frame.add(dcs);
    frame.add(postamble);

    return Uint8List.fromList(frame);
  }

  /// 发送命令并读取响应
  Future<Uint8List?> _sendCommand(int command, {List<int>? params, int timeoutMs = 500}) async {
    final data = [hostToPN532, command, ...?params];
    final frame = _buildFrame(data);
    
    _log('TX: ${frame.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    
    // 清空缓冲区并发送
    _port.flush();
    _port.write(frame);
    await Future.delayed(const Duration(milliseconds: 50));
    
    // 读取响应
    return await _readResponse(timeoutMs: timeoutMs);
  }

  /// 读取响应数据
  Future<Uint8List?> _readResponse({int timeoutMs = 500}) async {
    final buffer = <int>[];
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsedMilliseconds < timeoutMs) {
      final bytesAvailable = _port.bytesAvailable;
      if (bytesAvailable > 0) {
        final data = _port.read(bytesAvailable);
        buffer.addAll(data);
        if (buffer.length > 10) {
          break;
        }
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }
    
    if (buffer.isEmpty) {
      return null;
    }
    
    final response = Uint8List.fromList(buffer);
    _log('RX: ${response.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    return response;
  }

  /// 读取被动目标（寻卡）
  /// 
  /// [cardBaud]: 卡片类型
  /// - 0x00: ISO14443A (Mifare, NTAG等)
  /// - 0x01: FeliCa 212kb
  /// - 0x02: FeliCa 424kb
  /// - 0x03: ISO14443B
  /// - 0x04: Jewel
  Future<Map<String, dynamic>?> readPassiveTarget({int cardBaud = 0x00, int timeoutMs = 500}) async {
    final response = await _sendCommand(
      cmdInListPassiveTarget,
      params: [0x01, cardBaud],  // 最多1张卡
      timeoutMs: timeoutMs,
    );
    
    if (response == null) return null;
    
    // 解析响应: D5 4B NbTg [Tg SENS_RES SEL_RES NFCIDLength NFCID1...]
    for (int i = 0; i < response.length - 1; i++) {
      if (response[i] == pn532ToHost && response[i + 1] == 0x4B) {
        if (i + 2 < response.length) {
          final numTargets = response[i + 2];
          if (numTargets == 0) return null;
          
          if (i + 7 < response.length) {
            final atqa = response.sublist(i + 4, i + 6);
            final sak = response[i + 6];
            final uidLength = response[i + 7];
            
            if (i + 8 + uidLength <= response.length) {
              final uid = response.sublist(i + 8, i + 8 + uidLength);
              return {
                'uid': Uint8List.fromList(uid),
                'atqa': Uint8List.fromList(atqa),
                'sak': sak,
              };
            }
          }
        }
      }
    }
    
    return null;
  }

  /// Mifare认证
  Future<bool> mifareAuth(int blockNumber, Uint8List uid, {Uint8List? key, String keyType = 'A'}) async {
    key ??= defaultKey;
    
    final authCmd = keyType == 'A' ? mifareAuthA : mifareAuthB;
    final authData = [
      0x01,  // Tg (target number)
      authCmd,
      blockNumber,
      ...key,
      ...uid.sublist(0, 4),  // 只需要UID的前4字节
    ];
    
    final response = await _sendCommand(cmdInDataExchange, params: authData, timeoutMs: 500);
    
    if (response != null) {
      for (int i = 0; i < response.length - 1; i++) {
        if (response[i] == pn532ToHost && response[i + 1] == 0x41) {
          if (i + 2 < response.length) {
            return response[i + 2] == 0x00;  // 0x00 = 成功
          }
        }
      }
    }
    return false;
  }

  /// 读取Mifare块（16字节）
  Future<Uint8List?> mifareReadBlock(int blockNumber) async {
    final readData = [0x01, mifareRead, blockNumber];
    final response = await _sendCommand(cmdInDataExchange, params: readData, timeoutMs: 500);
    
    if (response != null) {
      for (int i = 0; i < response.length - 1; i++) {
        if (response[i] == pn532ToHost && response[i + 1] == 0x41) {
          if (i + 2 < response.length && response[i + 2] == 0x00) {
            if (i + 3 + 16 <= response.length) {
              return response.sublist(i + 3, i + 3 + 16);
            }
          }
        }
      }
    }
    return null;
  }

  /// 写入Mifare块（16字节）
  Future<bool> mifareWriteBlock(int blockNumber, Uint8List data) async {
    if (data.length != 16) {
      throw ArgumentError('数据必须为16字节');
    }
    
    final writeData = [0x01, mifareWrite, blockNumber, ...data];
    final response = await _sendCommand(cmdInDataExchange, params: writeData, timeoutMs: 500);
    
    if (response != null) {
      for (int i = 0; i < response.length - 1; i++) {
        if (response[i] == pn532ToHost && response[i + 1] == 0x41) {
          if (i + 2 < response.length) {
            return response[i + 2] == 0x00;
          }
        }
      }
    }
    return false;
  }

  /// 关闭连接
  void close() {
    _reader.close();
    _port.close();
    _log('连接已关闭');
  }

  /// 是否已打开
  bool get isOpen => _port.isOpen;
}
