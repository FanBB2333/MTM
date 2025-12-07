import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

/// 连接页面 - 扫描并连接PN532设备
class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  bool _isScanning = false;
  List<Map<String, String>> _devices = [];

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    setState(() => _isScanning = true);
    
    // 模拟扫描延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 模拟设备列表
    setState(() {
      _devices = [
        {'name': 'USB Serial', 'port': '/dev/cu.usbserial-110'},
      ];
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              // 刷新按钮
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
          
          const SizedBox(height: 8),
          Text(
            'Select a serial port to connect to your PN532 reader',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),
          
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
        return _DeviceCard(
          name: device['name'] ?? 'Unknown',
          port: device['port'] ?? '',
          onConnect: () {
            // TODO: 实际连接逻辑
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connecting to ${device['port']}...'),
                backgroundColor: AppColors.primary,
              ),
            );
          },
        );
      },
    );
  }
}

/// 设备卡片组件
class _DeviceCard extends StatelessWidget {
  final String name;
  final String port;
  final VoidCallback onConnect;

  const _DeviceCard({
    required this.name,
    required this.port,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onConnect,
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
                // 连接按钮
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
