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
    
    # ACK 和 NACK
    PN532_ACK = bytes([0x00, 0x00, 0xFF, 0x00, 0xFF, 0x00])
    PN532_NACK = bytes([0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00])
    
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
    
    def __init__(self, port, baudrate=115200, timeout=1, debug=False):
        """初始化PN532连接"""
        self.debug = debug
        self.ser = serial.Serial(port, baudrate=baudrate, timeout=timeout)
        time.sleep(0.1)
        self._wake_up()
    
    def _log(self, msg):
        """调试输出"""
        if self.debug:
            print(f"[DEBUG] {msg}")
    
    def _wake_up(self):
        """唤醒PN532 - 发送多个唤醒序列确保设备被唤醒"""
        # 清空缓冲区
        self.ser.reset_input_buffer()
        self.ser.reset_output_buffer()
        
        # 发送长唤醒序列（55 55 ... 连续发送）
        wakeup = bytes([0x55] * 16 + [0x00] * 4 + [0xFF, 0x03, 0xFD, 0xD4, 0x14, 0x01, 0x17, 0x00])
        
        for _ in range(3):  # 多次唤醒尝试
            self.ser.write(wakeup)
            time.sleep(0.1)
        
        # 清空响应
        time.sleep(0.2)
        self.ser.reset_input_buffer()
        self._log("唤醒序列已发送")
    
    def _write_frame(self, data):
        """写入数据帧"""
        length = len(data)
        lcs = (~length + 1) & 0xFF  # Length checksum
        
        frame = bytearray([
            self.PN532_PREAMBLE,
            self.PN532_STARTCODE1,
            self.PN532_STARTCODE2,
            length,
            lcs,
        ])
        
        dcs = 0  # Data checksum
        for byte in data:
            frame.append(byte)
            dcs += byte
        
        dcs = (~dcs + 1) & 0xFF
        frame.append(dcs)
        frame.append(self.PN532_POSTAMBLE)
        
        self._log(f"TX: {frame.hex()}")
        self.ser.write(frame)
        self.ser.flush()
    
    def _read_ack(self, timeout=0.5):
        """读取ACK响应"""
        start = time.time()
        data = bytearray()
        
        while time.time() - start < timeout:
            if self.ser.in_waiting > 0:
                data.extend(self.ser.read(self.ser.in_waiting))
                if len(data) >= 6:
                    break
            time.sleep(0.01)
        
        self._log(f"ACK RX: {data.hex() if data else 'empty'}")
        
        # 检查是否包含ACK
        if self.PN532_ACK in data:
            return True
        return len(data) >= 6
    
    def _read_response(self, timeout=1.0):
        """读取响应帧"""
        start = time.time()
        data = bytearray()
        
        while time.time() - start < timeout:
            if self.ser.in_waiting > 0:
                data.extend(self.ser.read(self.ser.in_waiting))
                # 检查是否收到完整帧（查找 00 00 FF）
                if len(data) > 6:
                    for i in range(len(data) - 2):
                        if data[i:i+3] == bytes([0x00, 0x00, 0xFF]):
                            if i + 3 < len(data):
                                frame_len = data[i + 3]
                                if frame_len != 0xFF:  # 不是扩展长度帧
                                    total_len = i + 3 + 2 + frame_len + 2  # header + len + lcs + data + dcs + postamble
                                    if len(data) >= total_len:
                                        break
            time.sleep(0.01)
        
        self._log(f"RX: {data.hex() if data else 'empty'}")
        return bytes(data) if data else None
    
    def _send_command(self, command, params=None, timeout=1.0):
        """发送命令并获取响应"""
        if params is None:
            params = []
        
        # 构建命令数据
        data = [self.PN532_HOSTTOPN532, command] + list(params)
        
        # 清空缓冲区
        self.ser.reset_input_buffer()
        
        # 发送命令
        self._write_frame(data)
        
        # 等待并读取ACK
        time.sleep(0.05)
        if not self._read_ack():
            self._log("未收到ACK")
            # 继续尝试读取响应
        
        # 读取响应数据
        response = self._read_response(timeout)
        return response
    
    def _parse_response(self, response, expected_cmd):
        """解析响应数据，返回数据部分（不包含TFI和命令码）"""
        if not response:
            return None
        
        # 查找响应帧 (D5 xx ...)
        expected_response_cmd = expected_cmd + 1  # 响应命令 = 请求命令 + 1
        
        for i in range(len(response) - 1):
            if response[i] == 0xD5 and response[i + 1] == expected_response_cmd:
                # 找到响应，向前查找帧头以获取长度
                for j in range(max(0, i - 5), i):
                    if j + 2 < len(response) and response[j:j+3] == bytes([0x00, 0x00, 0xFF]):
                        frame_len = response[j + 3]
                        data_start = i + 2  # 跳过 D5 和命令码
                        data_end = i + frame_len - 1  # 减去 TFI 字节
                        if data_end <= len(response):
                            return response[data_start:data_end]
                
                # 如果找不到帧头，尝试返回后续数据
                return response[i + 2:]
        
        return None
    
    def get_firmware_version(self):
        """获取固件版本"""
        # 多次尝试
        for attempt in range(3):
            response = self._send_command(self.PN532_COMMAND_GETFIRMWAREVERSION, timeout=0.5)
            
            if response:
                data = self._parse_response(response, self.PN532_COMMAND_GETFIRMWAREVERSION)
                if data and len(data) >= 4:
                    return {
                        'IC': hex(data[0]),
                        'Version': f'{data[1]}.{data[2]}',
                        'Support': hex(data[3])
                    }
            
            self._log(f"固件版本获取尝试 {attempt + 1} 失败")
            time.sleep(0.1)
        
        return None
    
    def sam_configuration(self, mode=0x01, timeout_50ms=0x14, irq=0x01):
        """
        配置SAM模式
        
        mode: 0x01 = Normal mode (SAM不使用), 0x02 = Virtual Card, 0x03 = Wired Card, 0x04 = Dual Card
        timeout_50ms: 超时时间，单位50ms，0x14 = 1秒
        irq: 是否使用IRQ
        """
        for attempt in range(3):
            response = self._send_command(
                self.PN532_COMMAND_SAMCONFIGURATION,
                [mode, timeout_50ms, irq],
                timeout=0.5
            )
            
            if response:
                # SAM配置成功的响应是 D5 15
                for i in range(len(response) - 1):
                    if response[i] == 0xD5 and response[i + 1] == 0x15:
                        return True
            
            self._log(f"SAM配置尝试 {attempt + 1} 失败")
            time.sleep(0.1)
        
        return False
    
    def read_passive_target(self, card_baud=0x00, timeout=0.5):
        """
        读取被动目标（寻卡）
        
        card_baud:
            0x00: ISO14443A (Mifare, NTAG等)
            0x01: FeliCa 212kb
            0x02: FeliCa 424kb
            0x03: ISO14443B
            0x04: Jewel
        
        返回: (UID, ATQA, SAK) 或 None
        """
        response = self._send_command(
            self.PN532_COMMAND_INLISTPASSIVETARGET,
            [0x01, card_baud],  # 最多1张卡, 波特率
            timeout=timeout
        )
        
        if not response:
            return None
        
        # 解析响应
        # 格式: D5 4B NbTg [Tg SENS_RES SEL_RES NFCIDLength NFCID1...]
        for i in range(len(response) - 1):
            if response[i] == 0xD5 and response[i + 1] == 0x4B:
                if i + 2 < len(response):
                    num_targets = response[i + 2]
                    if num_targets == 0:
                        return None
                    
                    if i + 7 < len(response):
                        # Tg = response[i + 3]
                        atqa = response[i + 4:i + 6]
                        sak = response[i + 6]
                        uid_length = response[i + 7]
                        
                        if i + 8 + uid_length <= len(response):
                            uid = response[i + 8: i + 8 + uid_length]
                            return {
                                'uid': bytes(uid),
                                'atqa': bytes(atqa),
                                'sak': sak
                            }
        
        return None
    
    def mifare_read_block(self, block_number, key=None, key_type='A'):
        """
        读取Mifare卡的一个块（16字节）
        
        block_number: 块号 (0-63 for 1K, 0-255 for 4K)
        key: 认证密钥（6字节），默认使用 FF FF FF FF FF FF
        key_type: 'A' 或 'B'
        """
        if key is None:
            key = bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
        
        # 首先需要对卡片进行认证
        auth_cmd = self.MIFARE_CMD_AUTH_A if key_type == 'A' else self.MIFARE_CMD_AUTH_B
        
        # 获取当前卡片信息
        card = self.read_passive_target()
        if not card:
            return None
        
        uid = card['uid']
        
        # 认证命令: Auth + Block + Key + UID
        auth_data = [auth_cmd, block_number] + list(key) + list(uid[:4])
        response = self._send_command(self.PN532_COMMAND_INDATAEXCHANGE, [0x01] + auth_data)
        
        if not response:
            return None
        
        # 读取块
        read_data = [self.MIFARE_CMD_READ, block_number]
        response = self._send_command(self.PN532_COMMAND_INDATAEXCHANGE, [0x01] + read_data)
        
        if response:
            data = self._parse_response(response, self.PN532_COMMAND_INDATAEXCHANGE)
            if data and len(data) >= 16:
                return data[:16]
        
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


def test_baudrates(port):
    """测试不同波特率"""
    baudrates = [115200, 38400, 19200, 9600, 57600, 230400]
    
    print("\n[*] 测试不同波特率...")
    
    for baud in baudrates:
        print(f"   尝试 {baud} bps...", end=" ")
        try:
            pn532 = PN532(port, baudrate=baud, timeout=0.5)
            firmware = pn532.get_firmware_version()
            pn532.close()
            
            if firmware:
                print(f"✅ 成功! 固件版本: {firmware['Version']}")
                return baud
            else:
                print("❌")
        except Exception as e:
            print(f"❌ ({e})")
    
    return None


def main():
    print("=" * 60)
    print("PN532 NFC 读卡器测试脚本 v2.0")
    print("=" * 60)
    
    # 解析命令行参数
    debug = '--debug' in sys.argv or '-d' in sys.argv
    
    if debug:
        print("[DEBUG模式已启用]")
    
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
    
    # 3. 测试波特率
    print(f"\n[3] 测试波特率...")
    best_baud = test_baudrates(pn532_port)
    
    if best_baud:
        print(f"\n✅ 最佳波特率: {best_baud} bps")
    else:
        print("\n⚠️  未能通过标准波特率获取固件版本")
        print("   设备可能工作正常，继续使用默认 115200 bps")
        best_baud = 115200
    
    # 4. 连接PN532
    print(f"\n[4] 连接到 {pn532_port} @ {best_baud} bps...")
    try:
        pn532 = PN532(pn532_port, baudrate=best_baud, debug=debug)
        print("✅ 串口连接成功")
    except Exception as e:
        print(f"❌ 连接失败: {e}")
        sys.exit(1)
    
    # 5. 获取固件版本
    print("\n[5] 获取PN532固件版本...")
    firmware = pn532.get_firmware_version()
    
    if firmware:
        print(f"✅ PN532已识别!")
        print(f"   IC: {firmware['IC']}")
        print(f"   固件版本: {firmware['Version']}")
        print(f"   支持功能: {firmware['Support']}")
    else:
        print("⚠️  无法获取固件版本")
        print("   这可能是某些PN532模块的正常行为")
    
    # 6. 配置SAM
    print("\n[6] 配置SAM模式...")
    if pn532.sam_configuration():
        print("✅ SAM配置成功")
    else:
        print("⚠️  SAM配置未确认（部分模块可能不需要）")
    
    # 7. 持续寻卡
    print("\n[7] 开始寻卡测试（按Ctrl+C退出）...")
    print("   请将NFC卡片放在PN532天线上方")
    print("-" * 50)
    
    last_uid = None
    read_count = 0
    
    try:
        while True:
            card = pn532.read_passive_target()
            
            if card:
                uid = card['uid']
                uid_hex = uid.hex().upper()
                uid_formatted = ':'.join(uid_hex[i:i+2] for i in range(0, len(uid_hex), 2))
                
                if uid != last_uid:
                    read_count += 1
                    atqa_hex = card['atqa'].hex().upper()
                    sak_hex = f"{card['sak']:02X}"
                    
                    print(f"\n✅ 检测到卡片 #{read_count}")
                    print(f"   UID:  {uid_formatted} ({len(uid)} bytes)")
                    print(f"   ATQA: {atqa_hex}")
                    print(f"   SAK:  {sak_hex}")
                    
                    # 根据SAK判断卡片类型
                    sak = card['sak']
                    if sak == 0x08:
                        print("   类型: Mifare Classic 1K")
                    elif sak == 0x18:
                        print("   类型: Mifare Classic 4K")
                    elif sak == 0x00:
                        print("   类型: Mifare Ultralight / NTAG")
                    elif sak == 0x20:
                        print("   类型: Mifare Plus / DESFire")
                    else:
                        print(f"   类型: 未知 (SAK=0x{sak:02X})")
                    
                    last_uid = uid
                
                time.sleep(0.5)  # 避免重复读取
            else:
                if last_uid:
                    print("\n[卡片已移开]")
                    last_uid = None
                print(".", end="", flush=True)
            
            time.sleep(0.1)
    
    except KeyboardInterrupt:
        print("\n\n用户中断测试")
    
    finally:
        pn532.close()
        print("✅ 连接已关闭")
    
    print("\n" + "=" * 60)
    print(f"测试完成，共检测 {read_count} 张卡片")
    print("=" * 60)


if __name__ == "__main__":
    main()
