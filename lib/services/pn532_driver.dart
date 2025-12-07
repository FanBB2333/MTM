import 'dart:async';
import 'dart:typed_data';
import 'package:flserial/flserial.dart';

/// PN532 NFC读卡器驱动类
/// 使用flserial库进行串口通信
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

  final FlSerial _serial;
  final String _portName;
  final bool debug;
  bool _isOpen = false;
  StreamSubscription<FlSerialEventArgs>? _dataSubscription;
  final List<int> _readBuffer = [];
  Completer<List<int>>? _readCompleter;

  PN532Driver._(this._serial, this._portName, {this.debug = false});

  /// 创建并初始化PN532驱动
  static Future<PN532Driver> open(String portName, {int baudRate = 115200, bool debug = false}) async {
    final serial = FlSerial();
    serial.init();
    
    // 打开端口
    final status = serial.openPort(portName, baudRate);
    if (status != FlOpenStatus.open) {
      serial.free();
      throw Exception('无法打开串口 $portName');
    }
    
    // 配置串口
    serial.setByteSize8();
    serial.setBitParityNone();
    serial.setStopBits1();
    serial.setFlowControlNone();
    
    final driver = PN532Driver._(serial, portName, debug: debug);
    driver._isOpen = true;
    
    // 设置数据监听
    driver._dataSubscription = serial.onSerialData.stream.listen((args) {
      if (args.len > 0) {
        final data = args.serial.readList();
        driver._readBuffer.addAll(data);
        driver._readCompleter?.complete(List.from(driver._readBuffer));
      }
    });
    
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
    
    _serial.write(wakeup);
    await Future.delayed(const Duration(milliseconds: 100));
    _readBuffer.clear();
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
    _readBuffer.clear();
    _serial.write(frame);
    
    // 等待响应
    await Future.delayed(const Duration(milliseconds: 50));
    return await _readResponse(timeoutMs: timeoutMs);
  }

  /// 读取响应数据
  Future<Uint8List?> _readResponse({int timeoutMs = 500}) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsedMilliseconds < timeoutMs) {
      // 尝试直接读取
      try {
        final data = _serial.readList();
        if (data.isNotEmpty) {
          _readBuffer.addAll(data);
        }
      } catch (e) {
        // 忽略读取错误
      }
      
      if (_readBuffer.length > 10) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }
    
    if (_readBuffer.isEmpty) {
      return null;
    }
    
    final response = Uint8List.fromList(_readBuffer);
    _readBuffer.clear();
    _log('RX: ${response.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    return response;
  }

  /// 读取被动目标（寻卡）
  Future<Map<String, dynamic>?> readPassiveTarget({int cardBaud = 0x00, int timeoutMs = 500}) async {
    final response = await _sendCommand(
      cmdInListPassiveTarget,
      params: [0x01, cardBaud],
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
      0x01,
      authCmd,
      blockNumber,
      ...key,
      ...uid.sublist(0, 4),
    ];
    
    final response = await _sendCommand(cmdInDataExchange, params: authData, timeoutMs: 500);
    
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
    if (_isOpen) {
      _dataSubscription?.cancel();
      _serial.closePort();
      _serial.free();
      _isOpen = false;
      _log('连接已关闭');
    }
  }

  /// 是否已打开
  bool get isOpen => _isOpen;
  
  /// 端口名称
  String get portName => _portName;
}
