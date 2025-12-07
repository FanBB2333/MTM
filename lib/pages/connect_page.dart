import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../services/serial_service.dart';
import '../services/pn532_service.dart';
import '../models/card_info.dart';

/// 连接页面 - 扫描并连接PN532设备
class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _serialService = SerialService.instance;
  final _pn532Service = PN532Service.instance;
  
  bool _isScanning = false;
  bool _isConnecting = false;
  List<SerialDeviceInfo> _devices = [];
  String? _selectedPort;

  @override
  void initState() {
    super.initState();
    _scanDevices();
    
    // 监听连接状态变化
    _pn532Service.addListener(_onConnectionChanged);
  }

  @override
  void dispose() {
    _pn532Service.removeListener(_onConnectionChanged);
    super.dispose();
  }

  void _onConnectionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _scanDevices() async {
    setState(() => _isScanning = true);
    
    // 短暂延迟以显示加载状态
    await Future.delayed(const Duration(milliseconds: 300));
    
    final devices = _serialService.listPorts();
    
    // 过滤掉系统端口
    final filteredDevices = devices.where((d) => 
      !d.port.contains('Bluetooth') && 
      !d.port.contains('debug')
    ).toList();
    
    // 自动选择可能的PN532端口
    final suggested = _serialService.findPN532Port();
    
    setState(() {
      _devices = filteredDevices;
      _selectedPort = suggested?.port;
      _isScanning = false;
    });
  }

  Future<void> _connectDevice(String port) async {
    setState(() => _isConnecting = true);
    
    final success = await _pn532Service.connect(port, debug: true);
    
    setState(() => _isConnecting = false);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已连接到 $port'),
            backgroundColor: AppColors.success,
          ),
        );
        // 开始持续扫描卡片
        _pn532Service.startScanning();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接失败，请检查设备'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _disconnectDevice() async {
    await _pn532Service.disconnect();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已断开连接'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _pn532Service.isConnected;
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Connect Device',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  if (isConnected)
                    TextButton.icon(
                      onPressed: _disconnectDevice,
                      icon: const Icon(CupertinoIcons.xmark_circle, size: 18),
                      label: const Text('Disconnect'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isScanning ? null : _scanDevices,
                    icon: AnimatedRotation(
                      turns: _isScanning ? 1 : 0,
                      duration: const Duration(milliseconds: 500),
                      child: Icon(
                        CupertinoIcons.arrow_clockwise,
                        color: _isScanning ? AppColors.textDisabled : AppColors.iconActive,
                      ),
                    ),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          Text(
            isConnected 
                ? 'Connected to ${_pn532Service.connectedPort}'
                : 'Select a serial port to connect to your PN532 reader',
            style: TextStyle(
              fontSize: 14,
              color: isConnected ? AppColors.success : AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 连接状态卡片
          if (isConnected) _buildConnectedCard(),
          
          if (!isConnected) ...[
            // 设备列表
            Expanded(
              child: _isScanning
                  ? const Center(
                      child: CupertinoActivityIndicator(radius: 16),
                    )
                  : _devices.isEmpty
                      ? _buildEmptyState()
                      : _buildDeviceList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withAlpha(75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PN532 Connected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _pn532Service.connectedPort ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              // 扫描状态
              if (_pn532Service.isScanning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoActivityIndicator(radius: 8),
                      SizedBox(width: 8),
                      Text(
                        'Scanning',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // 最后检测到的卡片
          _buildLastCardInfo(),
        ],
      ),
    );
  }

  Widget _buildLastCardInfo() {
    return StreamBuilder<CardInfo?>(
      stream: _pn532Service.cardStream,
      initialData: _pn532Service.lastCard,
      builder: (context, snapshot) {
        final card = snapshot.data;
        
        if (card == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.creditcard,
                  color: AppColors.textDisabled,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Place a card on the reader...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.creditcard,
                      color: AppColors.iconActive,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Card Detected!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCardInfoRow('UID', card.uidHex),
              _buildCardInfoRow('ATQA', card.atqaHex),
              _buildCardInfoRow('SAK', card.sakHex),
              _buildCardInfoRow('Type', card.cardType),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.antenna_radiowaves_left_right,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'No devices found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure your PN532 is connected via USB',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.separated(
      itemCount: _devices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isSelected = device.port == _selectedPort;
        
        return _DeviceCard(
          name: device.description,
          port: device.port,
          isSelected: isSelected,
          isConnecting: _isConnecting && isSelected,
          onConnect: () => _connectDevice(device.port),
        );
      },
    );
  }
}

/// 设备卡片组件
class _DeviceCard extends StatelessWidget {
  final String name;
  final String port;
  final bool isSelected;
  final bool isConnecting;
  final VoidCallback onConnect;

  const _DeviceCard({
    required this.name,
    required this.port,
    this.isSelected = false,
    this.isConnecting = false,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isConnecting ? null : onConnect,
          borderRadius: BorderRadius.circular(16),
          hoverColor: AppColors.primaryLight,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 图标
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.device_desktop,
                    color: AppColors.iconActive,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // 设备信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        port,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                // 连接按钮/状态
                if (isConnecting)
                  const CupertinoActivityIndicator(radius: 14)
                else
                  Icon(
                    CupertinoIcons.arrow_right_circle_fill,
                    color: AppColors.primary,
                    size: 32,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
