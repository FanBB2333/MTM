import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/card_info.dart';
import 'pn532_driver.dart';

/// PN532服务 - 业务层封装
/// 提供连接管理、卡片检测Stream等功能
class PN532Service extends ChangeNotifier {
  static final PN532Service _instance = PN532Service._();
  static PN532Service get instance => _instance;
  
  PN532Service._();

  PN532Driver? _driver;
  String? _connectedPort;
  bool _isScanning = false;
  CardInfo? _lastCard;
  Timer? _scanTimer;

  // Stream控制器
  final _cardStreamController = StreamController<CardInfo?>.broadcast();
  final _connectionStreamController = StreamController<bool>.broadcast();

  /// 卡片检测事件流
  Stream<CardInfo?> get cardStream => _cardStreamController.stream;
  
  /// 连接状态事件流
  Stream<bool> get connectionStream => _connectionStreamController.stream;

  /// 是否已连接
  bool get isConnected => _driver?.isOpen ?? false;
  
  /// 当前连接的端口
  String? get connectedPort => _connectedPort;
  
  /// 是否正在扫描卡片
  bool get isScanning => _isScanning;
  
  /// 最后检测到的卡片
  CardInfo? get lastCard => _lastCard;

  /// 最后一次连接错误信息
  String? _lastError;
  String? get lastError => _lastError;

  /// 连接到PN532设备
  Future<bool> connect(String portName, {int baudRate = 115200, bool debug = false}) async {
    _lastError = null;
    
    try {
      // 如果已连接，先断开
      if (isConnected) {
        await disconnect();
      }
      
      _driver = await PN532Driver.open(portName, baudRate: baudRate, debug: debug);
      _connectedPort = portName;
      _connectionStreamController.add(true);
      notifyListeners();
      
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('PN532连接失败: $e');
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    stopScanning();
    _driver?.close();
    _driver = null;
    _connectedPort = null;
    _lastCard = null;
    _connectionStreamController.add(false);
    notifyListeners();
  }

  /// 开始持续扫描卡片
  void startScanning({Duration interval = const Duration(milliseconds: 200)}) {
    if (!isConnected || _isScanning) return;
    
    _isScanning = true;
    notifyListeners();
    
    _scanTimer = Timer.periodic(interval, (_) async {
      await _scanOnce();
    });
  }

  /// 停止扫描
  void stopScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;
    _isScanning = false;
    notifyListeners();
  }

  /// 单次扫描
  Future<CardInfo?> _scanOnce() async {
    if (_driver == null) return null;
    
    try {
      final result = await _driver!.readPassiveTarget();
      
      if (result != null) {
        final card = CardInfo(
          uid: result['uid'] as Uint8List,
          atqa: result['atqa'] as Uint8List,
          sak: result['sak'] as int,
        );
        
        // 只在卡片变化时发送事件
        if (_lastCard != card) {
          _lastCard = card;
          _cardStreamController.add(card);
          notifyListeners();
        }
        
        return card;
      } else {
        // 卡片移开
        if (_lastCard != null) {
          _lastCard = null;
          _cardStreamController.add(null);
          notifyListeners();
        }
        return null;
      }
    } catch (e) {
      debugPrint('扫描错误: $e');
      return null;
    }
  }

  /// 单次读取卡片（不持续）
  Future<CardInfo?> readCard() async {
    if (_driver == null) return null;
    
    try {
      final result = await _driver!.readPassiveTarget(timeoutMs: 1000);
      
      if (result != null) {
        return CardInfo(
          uid: result['uid'] as Uint8List,
          atqa: result['atqa'] as Uint8List,
          sak: result['sak'] as int,
        );
      }
      return null;
    } catch (e) {
      debugPrint('读卡错误: $e');
      return null;
    }
  }

  /// Mifare认证
  Future<bool> mifareAuth(int blockNumber, Uint8List uid, {Uint8List? key, String keyType = 'A'}) async {
    if (_driver == null) return false;
    return await _driver!.mifareAuth(blockNumber, uid, key: key, keyType: keyType);
  }

  /// 读取Mifare块
  Future<Uint8List?> mifareReadBlock(int blockNumber) async {
    if (_driver == null) return null;
    return await _driver!.mifareReadBlock(blockNumber);
  }

  /// 写入Mifare块
  Future<bool> mifareWriteBlock(int blockNumber, Uint8List data) async {
    if (_driver == null) return false;
    return await _driver!.mifareWriteBlock(blockNumber, data);
  }

  /// 读取Mifare卡的多个扇区
  /// 返回 Map<扇区号, List<块数据>>
  Future<Map<int, List<Uint8List?>>> readMifareSectors({
    required Uint8List uid,
    Uint8List? keyA,
    Uint8List? keyB,
    int sectors = 16,  // Mifare 1K = 16扇区, 4K = 40扇区
  }) async {
    final result = <int, List<Uint8List?>>{};
    
    for (int sector = 0; sector < sectors; sector++) {
      final blocks = <Uint8List?>[];
      final firstBlock = sector * 4;
      
      // 尝试用Key A认证
      bool authed = await mifareAuth(firstBlock, uid, key: keyA, keyType: 'A');
      
      // 如果Key A失败，尝试Key B
      if (!authed && keyB != null) {
        authed = await mifareAuth(firstBlock, uid, key: keyB, keyType: 'B');
      }
      
      if (authed) {
        // 读取扇区的4个块
        for (int i = 0; i < 4; i++) {
          final blockData = await mifareReadBlock(firstBlock + i);
          blocks.add(blockData);
        }
      } else {
        // 认证失败，填充null
        blocks.addAll([null, null, null, null]);
      }
      
      result[sector] = blocks;
    }
    
    return result;
  }

  @override
  void dispose() {
    disconnect();
    _cardStreamController.close();
    _connectionStreamController.close();
    super.dispose();
  }
}
