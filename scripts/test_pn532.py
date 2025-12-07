#!/usr/bin/env python3
"""
PN532 NFC Reader Test Script for macOS
测试PN532读卡器连接和基本读卡功能

使用前请先安装依赖:
    pip install pyserial

运行测试:
    python test_pn532.py
"""

import serial
import serial.tools.list_ports
import time
import sys


class PN532:
    """PN532 NFC读卡器驱动类"""
    
    # PN532 命令常量
    PN532_PREAMBLE = 0x00
    PN532_STARTCODE1 = 0x00
    PN532_STARTCODE2 = 0xFF
    PN532_POSTAMBLE = 0x00
    PN532_HOSTTOPN532 = 0xD4
    PN532_PN532TOHOST = 0xD5
    
    # PN532 命令
    PN532_COMMAND_GETFIRMWAREVERSION = 0x02
    PN532_COMMAND_SAMCONFIGURATION = 0x14
    PN532_COMMAND_INLISTPASSIVETARGET = 0x4A
    PN532_COMMAND_INDATAEXCHANGE = 0x40
    
    # Mifare 命令
    MIFARE_CMD_AUTH_A = 0x60
    MIFARE_CMD_AUTH_B = 0x61
    MIFARE_CMD_READ = 0x30
    MIFARE_CMD_WRITE = 0xA0
    
    def __init__(self, port, baudrate=115200, timeout=1):
        """初始化PN532连接"""
        self.ser = serial.Serial(port, baudrate=baudrate, timeout=timeout)
        time.sleep(0.5)  # 等待设备就绪
        self._wake_up()
    
    def _wake_up(self):
        """唤醒PN532"""
        # 发送唤醒序列
        self.ser.write(bytes([0x55, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x03, 0xFD, 0xD4, 0x14, 0x01, 0x17, 0x00]))
        time.sleep(0.1)
        self.ser.reset_input_buffer()
    
    def _write_frame(self, data):
        """写入数据帧"""
        length = len(data)
        frame = [
            self.PN532_PREAMBLE,
            self.PN532_STARTCODE1,
            self.PN532_STARTCODE2,
            length,
            (~length + 1) & 0xFF,  # LCS
        ]
        
        checksum = 0
        for byte in data:
            frame.append(byte)
            checksum += byte
        
        frame.append((~checksum + 1) & 0xFF)  # DCS
        frame.append(self.PN532_POSTAMBLE)
        
        self.ser.write(bytes(frame))
        time.sleep(0.01)
    
    def _read_frame(self, timeout=1):
        """读取响应帧"""
        start_time = time.time()
        
        # 等待ACK或响应
        while time.time() - start_time < timeout:
            if self.ser.in_waiting > 0:
                break
            time.sleep(0.01)
        
        if self.ser.in_waiting == 0:
            return None
        
        # 读取所有可用数据
        time.sleep(0.1)  # 等待完整数据
        data = self.ser.read(self.ser.in_waiting)
        return data
    
    def _send_command(self, command, params=None):
        """发送命令并获取响应"""
        if params is None:
            params = []
        
        data = [self.PN532_HOSTTOPN532, command] + list(params)
        self._write_frame(data)
        
        # 读取ACK
        ack = self._read_frame()
        if not ack:
            return None
        
        # 读取响应
        response = self._read_frame()
        return response
    
    def get_firmware_version(self):
        """获取固件版本"""
        response = self._send_command(self.PN532_COMMAND_GETFIRMWAREVERSION)
        
        if response is None:
            return None
        
        # 解析响应
        try:
            # 查找响应数据
            for i in range(len(response)):
                if response[i] == 0xD5 and i + 1 < len(response) and response[i + 1] == 0x03:
                    if i + 5 < len(response):
                        ic = response[i + 2]
                        ver = response[i + 3]
                        rev = response[i + 4]
                        support = response[i + 5]
                        return {
                            'IC': hex(ic),
                            'Version': f'{ver}.{rev}',
                            'Support': hex(support)
                        }
        except Exception as e:
            print(f"解析固件版本失败: {e}")
        
        return None
    
    def sam_configuration(self):
        """配置SAM模式"""
        # Normal mode, timeout 1s
        response = self._send_command(self.PN532_COMMAND_SAMCONFIGURATION, [0x01, 0x14, 0x01])
        return response is not None
    
    def read_passive_target(self, card_baud=0x00, timeout=1):
        """
        读取被动目标（寻卡）
        
        card_baud:
            0x00: ISO14443A (Mifare)
            0x01: FeliCa 212kb
            0x02: FeliCa 424kb
            0x03: ISO14443B
            0x04: Jewel
        
        返回: UID 或 None
        """
        response = self._send_command(
            self.PN532_COMMAND_INLISTPASSIVETARGET,
            [0x01, card_baud]  # 最多1张卡, 波特率
        )
        
        if response is None:
            return None
        
        try:
            # 查找响应数据
            for i in range(len(response)):
                if response[i] == 0xD5 and i + 1 < len(response) and response[i + 1] == 0x4B:
                    num_targets = response[i + 2] if i + 2 < len(response) else 0
                    if num_targets > 0 and i + 7 < len(response):
                        uid_length = response[i + 7]
                        if i + 8 + uid_length <= len(response):
                            uid = response[i + 8: i + 8 + uid_length]
                            return bytes(uid)
        except Exception as e:
            print(f"解析卡片信息失败: {e}")
        
        return None
    
    def close(self):
        """关闭连接"""
        if self.ser and self.ser.is_open:
            self.ser.close()


def list_serial_ports():
    """列出所有可用的串口"""
    ports = serial.tools.list_ports.comports()
    return [(port.device, port.description) for port in ports]


def find_pn532_port():
    """尝试找到PN532设备的串口"""
    ports = list_serial_ports()
    
    # 常见的PN532/USB串口设备名称特征
    pn532_keywords = ['usb', 'serial', 'uart', 'ch340', 'cp210', 'ftdi', 'pl2303']
    
    for port, desc in ports:
        desc_lower = desc.lower()
        for keyword in pn532_keywords:
            if keyword in desc_lower:
                return port, desc
    
    # 如果没有找到匹配的，返回第一个tty.usbserial开头的端口
    for port, desc in ports:
        if 'usbserial' in port.lower() or 'usbmodem' in port.lower():
            return port, desc
    
    return None, None


def main():
    print("=" * 60)
    print("PN532 NFC 读卡器测试脚本")
    print("=" * 60)
    
    # 1. 列出所有串口
    print("\n[1] 扫描可用串口...")
    ports = list_serial_ports()
    
    if not ports:
        print("❌ 未找到任何串口设备！")
        print("   请检查PN532是否正确连接到USB端口")
        sys.exit(1)
    
    print(f"✅ 发现 {len(ports)} 个串口设备:")
    for port, desc in ports:
        print(f"   - {port}: {desc}")
    
    # 2. 尝试自动识别PN532端口
    print("\n[2] 尝试自动识别PN532设备...")
    pn532_port, pn532_desc = find_pn532_port()
    
    if pn532_port:
        print(f"✅ 可能的PN532设备: {pn532_port} ({pn532_desc})")
    else:
        print("⚠️  未能自动识别PN532设备")
        if ports:
            pn532_port = ports[0][0]
            print(f"   将使用第一个串口: {pn532_port}")
        else:
            sys.exit(1)
    
    # 允许用户手动指定端口
    user_port = input(f"\n按Enter使用 {pn532_port} 或输入其他端口: ").strip()
    if user_port:
        pn532_port = user_port
    
    # 3. 连接PN532
    print(f"\n[3] 连接到 {pn532_port}...")
    try:
        pn532 = PN532(pn532_port)
        print("✅ 串口连接成功")
    except Exception as e:
        print(f"❌ 连接失败: {e}")
        sys.exit(1)
    
    # 4. 获取固件版本
    print("\n[4] 获取PN532固件版本...")
    firmware = pn532.get_firmware_version()
    
    if firmware:
        print(f"✅ PN532已识别!")
        print(f"   IC: {firmware['IC']}")
        print(f"   固件版本: {firmware['Version']}")
        print(f"   支持功能: {firmware['Support']}")
    else:
        print("⚠️  无法获取固件版本，设备可能不是PN532")
        print("   尝试继续测试...")
    
    # 5. 配置SAM
    print("\n[5] 配置SAM模式...")
    if pn532.sam_configuration():
        print("✅ SAM配置成功")
    else:
        print("⚠️  SAM配置失败")
    
    # 6. 持续寻卡
    print("\n[6] 开始寻卡测试（按Ctrl+C退出）...")
    print("   请将NFC卡片放在PN532天线上方")
    print("-" * 40)
    
    try:
        while True:
            uid = pn532.read_passive_target()
            
            if uid:
                uid_hex = uid.hex().upper()
                uid_formatted = ':'.join(uid_hex[i:i+2] for i in range(0, len(uid_hex), 2))
                print(f"✅ 检测到卡片! UID: {uid_formatted} (长度: {len(uid)} bytes)")
                time.sleep(1)  # 避免重复读取
            else:
                print(".", end="", flush=True)
            
            time.sleep(0.2)
    
    except KeyboardInterrupt:
        print("\n\n用户中断测试")
    
    finally:
        pn532.close()
        print("✅ 连接已关闭")
    
    print("\n" + "=" * 60)
    print("测试完成")
    print("=" * 60)


if __name__ == "__main__":
    main()
