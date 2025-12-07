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
    PN532_COMMAND_RFCONFIGURATION = 0x32
    PN532_COMMAND_INLISTPASSIVETARGET = 0x4A
    PN532_COMMAND_INDATAEXCHANGE = 0x40
    
    # Mifare 命令
    MIFARE_CMD_AUTH_A = 0x60
    MIFARE_CMD_AUTH_B = 0x61
    MIFARE_CMD_READ = 0x30
    MIFARE_CMD_WRITE = 0xA0
    
    # 默认密钥
    DEFAULT_KEY = bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
    
    def __init__(self, port, baudrate=115200, timeout=1, debug=False):
        """初始化PN532连接"""
        self.debug = debug
        self.ser = serial.Serial(port, baudrate=baudrate, timeout=timeout)
        time.sleep(0.1)
        
        # 1. 软复位 (相当于恢复初始状态)
        self.reset()
        
        # 2. 获取版本信息 (确认连接正常)
        ver = self.get_firmware_version()
        if ver:
            print(f"✅ PN532 Firmware: v{ver['ver']}.{ver['rev']}")
        
        # 3. 重新配置
        self.sam_configuration()
        self.rf_configuration()
    
    def reset(self):
        """软复位：发送ACK终止指令并唤醒"""
        # ACK frame: 00 00 FF 00 FF 00
        # 用于终止任何正在进行的指令
        self.ser.write(bytes([0x00, 0x00, 0xFF, 0x00, 0xFF, 0x00]))
        time.sleep(0.05)
        self._wake_up()

    def get_firmware_version(self):
        """获取固件版本"""
        response = self._send_command(self.PN532_COMMAND_GETFIRMWAREVERSION)
        if response:
            # 查找响应帧: D5 03 <IC> <Ver> <Rev> <Support>
            for i in range(len(response) - 4):
                if response[i] == 0xD5 and response[i+1] == 0x03:
                    return {'ic': response[i+2], 'ver': response[i+3], 'rev': response[i+4]}
        return None

    def _log(self, msg):
        """调试输出"""
        if self.debug:
            print(f"[DEBUG] {msg}")
    
    def _wake_up(self):
        """唤醒PN532"""
        self.ser.reset_input_buffer()
        self.ser.reset_output_buffer()
        # 发送唤醒序列
        wakeup = bytes([0x55] * 16 + [0x00] * 4)
        self.ser.write(wakeup)
        time.sleep(0.1)
        self.ser.reset_input_buffer()
    
    def _write_frame(self, data):
        """写入数据帧"""
        length = len(data)
        lcs = (~length + 1) & 0xFF
        
        frame = bytearray([
            self.PN532_PREAMBLE,
            self.PN532_STARTCODE1,
            self.PN532_STARTCODE2,
            length,
            lcs,
        ])
        
        dcs = 0
        for byte in data:
            frame.append(byte)
            dcs += byte
        
        dcs = (~dcs + 1) & 0xFF
        frame.append(dcs)
        frame.append(self.PN532_POSTAMBLE)
        
        self._log(f"TX: {frame.hex()}")
        self.ser.write(frame)
        self.ser.flush()
    
    def _read_response(self, timeout=1.0):
        """读取响应帧"""
        start = time.time()
        data = bytearray()
        
        while time.time() - start < timeout:
            if self.ser.in_waiting > 0:
                data.extend(self.ser.read(self.ser.in_waiting))
                if len(data) > 10:
                    break
            time.sleep(0.01)
        
        self._log(f"RX: {data.hex() if data else 'empty'}")
        return bytes(data) if data else None
    
    def _send_command(self, command, params=None, timeout=1.0):
        """发送命令并获取响应"""
        if params is None:
            params = []
        
        data = [self.PN532_HOSTTOPN532, command] + list(params)
        self.ser.reset_input_buffer()
        self._write_frame(data)
        time.sleep(0.05)
        
        return self._read_response(timeout)
    
    def sam_configuration(self):
        """配置SAM (Secure Access Module) 以启用正常模式"""
        # Mode: 0x01 (Normal mode)
        # Timeout: 0x14 (50ms * 20 = 1s)
        # IRQ: 0x01 (Use IRQ pin)
        params = [0x01, 0x14, 0x01]
        self._send_command(self.PN532_COMMAND_SAMCONFIGURATION, params, timeout=0.5)

    def rf_configuration(self):
        """配置RF参数 (MaxRetries)"""
        # ConfigItem: 0x05 (MaxRetries)
        # MxRtyATR: 0xFF (default)
        # MxRtyPSL: 0x01 (default)
        # MxRtyPassiveActivation: 0x05 (尝试5次，增加寻卡成功率)
        params = [0x05, 0xFF, 0x01, 0x05]
        self._send_command(self.PN532_COMMAND_RFCONFIGURATION, params, timeout=0.5)

    def read_passive_target(self, card_baud=0x00, timeout=1.0):
        """
        读取被动目标（寻卡）
        
        card_baud:
            0x00: ISO14443A (Mifare, NTAG等)
            0x01: FeliCa 212kb
            0x02: FeliCa 424kb
            0x03: ISO14443B
            0x04: Jewel
        
        返回: {uid, atqa, sak} 或 None
        """
        response = self._send_command(
            self.PN532_COMMAND_INLISTPASSIVETARGET,
            [0x01, card_baud],
            timeout=timeout
        )
        
        if not response:
            return None
        
        # 解析响应: D5 4B NbTg [Tg SENS_RES SEL_RES NFCIDLength NFCID1...]
        for i in range(len(response) - 1):
            if response[i] == 0xD5 and response[i + 1] == 0x4B:
                if i + 2 < len(response):
                    num_targets = response[i + 2]
                    if num_targets == 0:
                        return None
                    
                    if i + 7 < len(response):
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
    
    def mifare_auth(self, block_number, uid, key=None, key_type='A'):
        """Mifare认证"""
        if key is None:
            key = self.DEFAULT_KEY
        
        auth_cmd = self.MIFARE_CMD_AUTH_A if key_type == 'A' else self.MIFARE_CMD_AUTH_B
        auth_data = [0x01, auth_cmd, block_number] + list(key) + list(uid[:4])
        
        response = self._send_command(self.PN532_COMMAND_INDATAEXCHANGE, auth_data, timeout=0.5)
        
        if response:
            for i in range(len(response) - 1):
                if response[i] == 0xD5 and response[i + 1] == 0x41:
                    if i + 2 < len(response):
                        return response[i + 2] == 0x00  # 0x00 = 成功
        return False
    
    def mifare_read_block(self, block_number):
        """读取Mifare块（16字节）"""
        read_data = [0x01, self.MIFARE_CMD_READ, block_number]
        response = self._send_command(self.PN532_COMMAND_INDATAEXCHANGE, read_data, timeout=0.5)
        
        if response:
            for i in range(len(response) - 1):
                if response[i] == 0xD5 and response[i + 1] == 0x41:
                    if i + 2 < len(response) and response[i + 2] == 0x00:
                        if i + 3 + 16 <= len(response):
                            return bytes(response[i + 3: i + 3 + 16])
        return None
    
    def mifare_write_block(self, block_number, data):
        """写入Mifare块（16字节）"""
        if len(data) != 16:
            raise ValueError("数据必须为16字节")
        
        write_data = [0x01, self.MIFARE_CMD_WRITE, block_number] + list(data)
        response = self._send_command(self.PN532_COMMAND_INDATAEXCHANGE, write_data, timeout=0.5)
        
        if response:
            for i in range(len(response) - 1):
                if response[i] == 0xD5 and response[i + 1] == 0x41:
                    if i + 2 < len(response):
                        return response[i + 2] == 0x00
        return False
    
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
    
    for port, desc in ports:
        if 'usbserial' in port.lower() or 'usbmodem' in port.lower():
            return port, desc
    
    pn532_keywords = ['usb', 'serial', 'uart', 'ch340', 'cp210', 'ftdi', 'pl2303']
    for port, desc in ports:
        desc_lower = desc.lower()
        for keyword in pn532_keywords:
            if keyword in desc_lower:
                return port, desc
    
    return None, None


def get_card_type(sak):
    """根据SAK判断卡片类型"""
    card_types = {
        0x08: "Mifare Classic 1K",
        0x18: "Mifare Classic 4K",
        0x00: "Mifare Ultralight / NTAG",
        0x09: "Mifare Mini",
        0x10: "Mifare Plus 2K",
        0x11: "Mifare Plus 4K",
        0x20: "Mifare Plus / DESFire / JCOP",
        0x28: "SmartMX with Mifare 1K",
        0x38: "SmartMX with Mifare 4K",
    }
    return card_types.get(sak, f"未知 (SAK=0x{sak:02X})")


def main():
    print("=" * 50)
    print("PN532 NFC 读卡器测试脚本")
    print("=" * 50)
    
    debug = '--debug' in sys.argv or '-d' in sys.argv
    
    # 1. 扫描串口
    print("\n[1] 扫描串口...")
    ports = list_serial_ports()
    
    if not ports:
        print("❌ 未找到串口设备！请检查PN532连接")
        sys.exit(1)
    
    print(f"✅ 发现 {len(ports)} 个设备:")
    for port, desc in ports:
        print(f"   - {port}: {desc}")
    
    # 2. 识别PN532
    print("\n[2] 识别PN532...")
    pn532_port, pn532_desc = find_pn532_port()
    
    if pn532_port:
        print(f"✅ 找到: {pn532_port}")
    else:
        print("⚠️  未自动识别，使用第一个串口")
        pn532_port = ports[0][0] if ports else None
    
    user_port = input(f"\n按Enter使用 {pn532_port} 或输入端口: ").strip()
    if user_port:
        pn532_port = user_port
    
    # 3. 连接
    print(f"\n[3] 连接到 {pn532_port}...")
    try:
        pn532 = PN532(pn532_port, debug=debug)
        print("✅ 连接成功")
    except Exception as e:
        print(f"❌ 连接失败: {e}")
        sys.exit(1)
    
    # 4. 寻卡测试
    print("\n[4] 寻卡测试（Ctrl+C 退出）")
    print("   将NFC卡片放在PN532上方")
    print("-" * 50)
    
    last_uid = None
    count = 0
    
    try:
        while True:
            card = pn532.read_passive_target()
            
            if card:
                uid = card['uid']
                
                if uid != last_uid:
                    count += 1
                    uid_str = ':'.join(f'{b:02X}' for b in uid)
                    atqa_str = card['atqa'].hex().upper()
                    
                    print(f"\n✅ 卡片 #{count}")
                    print(f"   UID:  {uid_str} ({len(uid)} bytes)")
                    print(f"   ATQA: {atqa_str}")
                    print(f"   SAK:  0x{card['sak']:02X}")
                    print(f"   类型: {get_card_type(card['sak'])}")
                    
                    # 尝试读取块0（Mifare Classic）
                    if card['sak'] in [0x08, 0x18]:
                        if pn532.mifare_auth(0, uid):
                            block0 = pn532.mifare_read_block(0)
                            if block0:
                                print(f"   Block0: {block0.hex().upper()}")
                    
                    last_uid = uid
                
                time.sleep(0.3)
            else:
                if last_uid:
                    print("\n[卡片移开]")
                    last_uid = None
                print(".", end="", flush=True)
            
            time.sleep(0.1)
    
    except KeyboardInterrupt:
        print("\n\n已停止")
    finally:
        pn532.close()
    
    print(f"\n共检测 {count} 张卡片")


if __name__ == "__main__":
    main()
