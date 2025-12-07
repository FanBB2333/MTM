import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../models/card_dump.dart';

/// 卡片文件服务
/// 处理卡片数据的保存和加载
class CardFileService {
  static final CardFileService _instance = CardFileService._();
  static CardFileService get instance => _instance;
  
  CardFileService._();

  /// 保存卡片转储到文件
  /// 返回保存的文件路径，如果取消则返回 null
  Future<String?> saveCardDump(CardDump dump, {String? suggestedName}) async {
    try {
      // 生成默认文件名 (不包含扩展名，file_picker 会自动添加)
      final defaultName = suggestedName ?? 
          'card_${DateTime.now().millisecondsSinceEpoch}';
      
      // 打开保存对话框
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Card Dump',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['mfc', 'bin'],
      );
      
      if (result == null) return null;
      
      // 写入文件 (file_picker already appends extension based on allowedExtensions)
      final file = File(result);
      await file.writeAsBytes(dump.toBytes());
      
      return result;
    } catch (e) {
      throw Exception('Failed to save card dump: $e');
    }
  }

  /// 从文件加载卡片转储
  /// 返回加载的 CardDump，如果取消则返回 null
  Future<CardDump?> loadCardDump() async {
    try {
      // 打开文件选择对话框
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Load Card Dump',
        type: FileType.custom,
        allowedExtensions: ['mfc', 'bin'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) return null;
      
      final filePath = result.files.single.path;
      if (filePath == null) return null;
      
      // 读取文件
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // 验证文件大小
      if (bytes.length != 1024 && bytes.length != 4096) {
        throw Exception('Invalid dump file size: ${bytes.length} bytes. Expected 1024 (1K) or 4096 (4K).');
      }
      
      return CardDump.fromBytes(bytes);
    } catch (e) {
      throw Exception('Failed to load card dump: $e');
    }
  }
}
