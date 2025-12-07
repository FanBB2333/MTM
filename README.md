# **M**ifare **T**ool on **M**acOS(a simple PN532 NFC Tool)

A cross-platform Flutter application for reading and writing NFC/RFID cards using the PN532 module via USB/TTL serial connection.

## Features

- **Device Connection**: Auto-detect and connect to PN532 devices via serial port
- **Read Card**: Read Mifare Classic 1K/4K card data with customizable keys
  - Full card reading (all sectors)
  - Single sector reading
  - Single block reading
  - Hex data visualization with color-coded blocks
- **Write Card**: Write data to blank or UID cards
  - Load data from saved dump files
  - Clone from current read buffer
  - Support for manufacturer block (Block 0) writing
- **Saved Cards**: Manage saved card dump files (.dump, .mfc, .bin)
  - Save read card data to file
  - Load card data for writing
- **Multi-language Support**: English, Simplified Chinese, Traditional Chinese
- **Modern UI**: Minimalist design with soft color palette and smooth animations

## Supported Platforms

- macOS
- Windows(Not Tested)
- Linux(Not Tested)

## Supported Hardware

- PN532 NFC/RFID module (USB/TTL serial connection)
- Mifare Classic 1K/4K cards

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.10.3 or higher)
- A PN532 NFC module connected via USB/TTL adapter

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/FanBB2333/MTM.git
   cd MTM
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run -d macos
   ```


## Usage

1. **Connect Device**: 
   - Navigate to the Connect page
   - Click the refresh button to scan for available serial ports
   - Select your PN532 device from the list to connect

2. **Read Card**:
   - Go to the Read Card page
   - Select reading mode (Full Card / Sector / Block)
   - Enter authentication keys if needed (default: FFFFFFFFFFFF)
   - Place a card on the reader and click "Start Reading"
   - View the card data in hex format

3. **Write Card**:
   - Go to the Write Card page
   - Load card data from a saved file or use data from a previous read
   - Place a blank card on the reader and start writing

4. **Save/Load Card Data**:
   - After reading a card, click "Save" to export the data to a file
   - Use the Saved Cards page to manage your dump files


## Dependencies

- `flserial`: Serial port communication
- `file_picker`: File save/load dialogs
- `google_fonts`: Typography
- `flutter_localizations`: Multi-language support

## License

This project is for personal/educational use.

## Acknowledgments

- Inspired by [Chameleon Ultra GUI](https://github.com/GameTec-live/ChameleonUltraGUI) for UI design
- PN532 protocol documentation
