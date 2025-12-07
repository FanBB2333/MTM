import 'package:flserial/flserial.dart';
import '../models/card_info.dart';

/// 串口服务 - 管理串口设备的连接和通信
class SerialService {
  static final SerialService _instance = SerialService._();
  static SerialService get instance => _instance;
  
  SerialService._();

  /// 列出所有可用的串口设备
  List<SerialDeviceInfo> listPorts() {
    final devices = <SerialDeviceInfo>[];
    
    try {
      // FlSerial.listPorts() 返回格式: "/dev/cu.usbserial-10 - n/a - n/a"
      final ports = FlSerial.listPorts();
      for (final portInfo in ports) {
        // 解析端口名和描述
        final parsed = _parsePortInfo(portInfo);
        devices.add(SerialDeviceInfo(
          port: parsed['port']!,
          description: parsed['description']!,
        ));
      }
    } catch (e) {
      print('[SerialService] listPorts error: $e');
    }
    
    return devices;
  }

  /// 解析端口信息字符串
  /// 输入格式: "/dev/cu.usbserial-10 - n/a - n/a" 或 "COM3 - USB-SERIAL CH340 - n/a"
  /// 返回: {port: 实际端口名, description: 描述}
  Map<String, String> _parsePortInfo(String portInfo) {
    // 按 " - " 分割
    final parts = portInfo.split(' - ');
    
    if (parts.isEmpty) {
      return {'port': portInfo, 'description': 'Unknown'};
    }
    
    final port = parts[0].trim();
    String description = 'Serial Port';
    
    // 如果有第二部分且不是 "n/a"，使用它作为描述
    if (parts.length > 1 && parts[1].trim().toLowerCase() != 'n/a') {
      description = parts[1].trim();
    } else {
      // 根据端口名推断描述
      description = _getPortDescription(port);
    }
    
    return {'port': port, 'description': description};
  }

  /// 获取端口描述
  String _getPortDescription(String port) {
    final portLower = port.toLowerCase();
    if (portLower.contains('usbserial') || portLower.contains('usbmodem')) {
      return 'USB Serial';
    } else if (portLower.contains('bluetooth')) {
      return 'Bluetooth';
    } else if (portLower.contains('debug')) {
      return 'Debug Console';
    } else if (portLower.startsWith('com')) {
      return 'COM Port';
    }
    return 'Serial Port';
  }

  /// 查找可能是PN532的串口
  SerialDeviceInfo? findPN532Port() {
    final ports = listPorts();
    
    // 优先查找 USB Serial 设备
    for (final device in ports) {
      final portLower = device.port.toLowerCase();
      if (portLower.contains('usbserial') || portLower.contains('usbmodem')) {
        return device;
      }
    }
    
    // 过滤掉系统端口
    final filtered = ports.where((d) => 
      !d.port.toLowerCase().contains('bluetooth') && 
      !d.port.toLowerCase().contains('debug')
    ).toList();
    
    return filtered.isNotEmpty ? filtered.first : null;
  }
}
