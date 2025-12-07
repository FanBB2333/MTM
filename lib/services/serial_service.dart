import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../models/card_info.dart';

/// 串口服务 - 管理串口设备的连接和通信
class SerialService {
  static final SerialService _instance = SerialService._();
  static SerialService get instance => _instance;
  
  SerialService._();

  /// 列出所有可用的串口设备
  List<SerialDeviceInfo> listPorts() {
    final ports = SerialPort.availablePorts;
    final devices = <SerialDeviceInfo>[];
    
    for (final portName in ports) {
      try {
        final port = SerialPort(portName);
        devices.add(SerialDeviceInfo(
          port: portName,
          description: port.description ?? 'Unknown',
          manufacturer: port.manufacturer,
          serialNumber: port.serialNumber,
        ));
        port.dispose();
      } catch (e) {
        // 忽略无法访问的端口
        devices.add(SerialDeviceInfo(
          port: portName,
          description: 'Unknown',
        ));
      }
    }
    
    return devices;
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
    
    // 其次查找包含特定关键字的设备
    const keywords = ['usb', 'serial', 'uart', 'ch340', 'cp210', 'ftdi', 'pl2303'];
    for (final device in ports) {
      final descLower = device.description.toLowerCase();
      for (final keyword in keywords) {
        if (descLower.contains(keyword)) {
          return device;
        }
      }
    }
    
    // 返回第一个非系统端口
    for (final device in ports) {
      if (!device.port.contains('Bluetooth') && !device.port.contains('debug')) {
        return device;
      }
    }
    
    return ports.isNotEmpty ? ports.first : null;
  }
}
