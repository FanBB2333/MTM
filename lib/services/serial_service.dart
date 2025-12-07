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
      // FlSerial.listPorts() 是静态方法
      final ports = FlSerial.listPorts();
      for (final port in ports) {
        devices.add(SerialDeviceInfo(
          port: port,
          description: _getPortDescription(port),
        ));
      }
    } catch (e) {
      // 忽略错误
    }
    
    return devices;
  }

  /// 获取端口描述
  String _getPortDescription(String port) {
    if (port.contains('usbserial') || port.contains('usbmodem')) {
      return 'USB Serial';
    } else if (port.contains('Bluetooth')) {
      return 'Bluetooth';
    } else if (port.contains('debug')) {
      return 'Debug Console';
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
      !d.port.contains('Bluetooth') && 
      !d.port.contains('debug')
    ).toList();
    
    return filtered.isNotEmpty ? filtered.first : null;
  }
}
