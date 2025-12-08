import 'dart:async';
import 'dart:io';

/// 卡片破解服务
/// 封装 mfoc 和 mfcuk 命令行工具调用
class CrackService {
  static final CrackService instance = CrackService._();
  CrackService._();

  Process? _currentProcess;
  bool _isRunning = false;
  
  final StreamController<String> _outputController = StreamController<String>.broadcast();
  
  /// 输出流
  Stream<String> get outputStream => _outputController.stream;
  
  /// 是否正在运行
  bool get isRunning => _isRunning;

  /// 检查工具是否可用
  Future<bool> isToolAvailable(String tool) async {
    try {
      final result = await Process.run('which', [tool]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// 使用 mfoc 破解卡片
  /// mfoc 使用嵌套攻击，需要至少知道一个扇区的密钥
  Future<bool> runMfoc({
    required String outputPath,
    List<String>? knownKeys,
    int probes = 20,
    int tolerance = 20,
  }) async {
    if (_isRunning) {
      _outputController.add('> Error: Another process is already running');
      return false;
    }

    // 检查 mfoc 是否可用
    if (!await isToolAvailable('mfoc')) {
      _outputController.add('> Error: mfoc not found');
      _outputController.add('> Please install mfoc:');
      _outputController.add('>   macOS: brew install mfoc');
      _outputController.add('>   Linux: sudo apt install mfoc');
      return false;
    }

    _isRunning = true;
    
    try {
      final args = <String>[
        '-O', outputPath,
        '-P', probes.toString(),
        '-T', tolerance.toString(),
      ];
      
      // 添加已知密钥
      if (knownKeys != null) {
        for (final key in knownKeys) {
          if (key.length == 12) {
            args.addAll(['-k', key.toUpperCase()]);
          }
        }
      }

      _outputController.add('> Starting mfoc...');
      _outputController.add('> Command: mfoc ${args.join(' ')}');
      _outputController.add('');

      _currentProcess = await Process.start('mfoc', args);
      
      // 监听 stdout
      _currentProcess!.stdout.transform(const SystemEncoding().decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.isNotEmpty) {
            _outputController.add(line);
          }
        }
      });

      // 监听 stderr
      _currentProcess!.stderr.transform(const SystemEncoding().decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.isNotEmpty) {
            _outputController.add('[stderr] $line');
          }
        }
      });

      // 等待进程结束
      final exitCode = await _currentProcess!.exitCode;
      
      if (exitCode == 0) {
        _outputController.add('');
        _outputController.add('> mfoc completed successfully!');
        _outputController.add('> Output saved to: $outputPath');
        return true;
      } else {
        _outputController.add('');
        _outputController.add('> mfoc failed with exit code: $exitCode');
        return false;
      }
    } catch (e) {
      _outputController.add('> Error running mfoc: $e');
      return false;
    } finally {
      _isRunning = false;
      _currentProcess = null;
    }
  }

  /// 使用 mfcuk 破解卡片
  /// mfcuk 使用 DarkSide 攻击，不需要已知密钥
  Future<bool> runMfcuk({
    String? outputPath,
    int sector = 0,
    String keyType = 'A',
    int verbosity = 3,
  }) async {
    if (_isRunning) {
      _outputController.add('> Error: Another process is already running');
      return false;
    }

    // 检查 mfcuk 是否可用
    if (!await isToolAvailable('mfcuk')) {
      _outputController.add('> Error: mfcuk not found');
      _outputController.add('> Please install mfcuk:');
      _outputController.add('>   macOS: brew install mfcuk');
      _outputController.add('>   Linux: sudo apt install mfcuk');
      return false;
    }

    _isRunning = true;
    
    try {
      final args = <String>[
        '-C',
        '-R', '$sector:$keyType',
        '-s', '250',
        '-S', '250',
        '-v', verbosity.toString(),
      ];
      
      if (outputPath != null) {
        args.addAll(['-o', outputPath]);
      }

      _outputController.add('> Starting mfcuk...');
      _outputController.add('> Command: mfcuk ${args.join(' ')}');
      _outputController.add('> Note: mfcuk can take a long time (up to hours)');
      _outputController.add('');

      _currentProcess = await Process.start('mfcuk', args);
      
      // 监听 stdout
      _currentProcess!.stdout.transform(const SystemEncoding().decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.isNotEmpty) {
            _outputController.add(line);
          }
        }
      });

      // 监听 stderr
      _currentProcess!.stderr.transform(const SystemEncoding().decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.isNotEmpty) {
            _outputController.add('[stderr] $line');
          }
        }
      });

      // 等待进程结束
      final exitCode = await _currentProcess!.exitCode;
      
      if (exitCode == 0) {
        _outputController.add('');
        _outputController.add('> mfcuk completed successfully!');
        if (outputPath != null) {
          _outputController.add('> Output saved to: $outputPath');
        }
        return true;
      } else {
        _outputController.add('');
        _outputController.add('> mfcuk finished with exit code: $exitCode');
        return false;
      }
    } catch (e) {
      _outputController.add('> Error running mfcuk: $e');
      return false;
    } finally {
      _isRunning = false;
      _currentProcess = null;
    }
  }

  /// 停止当前运行的进程
  void stopProcess() {
    if (_currentProcess != null) {
      _outputController.add('');
      _outputController.add('> Stopping process...');
      _currentProcess!.kill(ProcessSignal.sigterm);
      _isRunning = false;
    }
  }

  /// 清空输出
  void clearOutput() {
    // 输出已在 widget 端管理
  }

  /// 释放资源
  void dispose() {
    stopProcess();
    _outputController.close();
  }
}
