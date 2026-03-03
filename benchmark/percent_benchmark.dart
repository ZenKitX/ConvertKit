// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:convert_kit/convert_kit.dart';

/// 百分号编解码性能基准测试
void main() {
  print('=== 百分号编解码性能基准测试 ===\n');

  // 测试数据
  final smallData = 'Hello World!'.codeUnits;
  final mediumData = List.generate(1000, (i) => 65 + (i % 26)); // A-Z 重复
  final largeData = List.generate(100000, (i) => 65 + (i % 26));

  // 包含特殊字符的数据
  final specialData = 'Hello World! 你好世界 @#\$%^&*()'.codeUnits;

  // 编码基准测试
  print('--- 编码性能 ---');
  _benchmarkEncode('小数据 (12 字节)', smallData, 10000);
  _benchmarkEncode('中等数据 (1KB)', mediumData, 1000);
  _benchmarkEncode('大数据 (100KB)', largeData, 100);
  _benchmarkEncode('特殊字符数据', specialData, 10000);

  print('\n--- 解码性能 ---');
  final smallEncoded = percent.encode(smallData);
  final mediumEncoded = percent.encode(mediumData);
  final largeEncoded = percent.encode(largeData);
  final specialEncoded = percent.encode(specialData);

  _benchmarkDecode('小数据 (12 字节)', smallEncoded, 10000);
  _benchmarkDecode('中等数据 (1KB)', mediumEncoded, 1000);
  _benchmarkDecode('大数据 (100KB)', largeEncoded, 100);
  _benchmarkDecode('特殊字符数据', specialEncoded, 10000);

  print('\n--- 往返转换性能 ---');
  _benchmarkRoundTrip('小数据 (12 字节)', smallData, 10000);
  _benchmarkRoundTrip('中等数据 (1KB)', mediumData, 1000);
  _benchmarkRoundTrip('大数据 (100KB)', largeData, 100);
  _benchmarkRoundTrip('特殊字符数据', specialData, 10000);
}

void _benchmarkEncode(String name, List<int> data, int iterations) {
  final stopwatch = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    percent.encode(data);
  }

  stopwatch.stop();
  final totalMs = stopwatch.elapsedMilliseconds;
  final avgMs = totalMs / iterations;
  final throughput =
      (data.length * iterations) / (totalMs / 1000) / 1024 / 1024;

  print('$name:');
  print('  总时间: ${totalMs}ms');
  print('  平均时间: ${avgMs.toStringAsFixed(3)}ms');
  print('  吞吐量: ${throughput.toStringAsFixed(2)} MB/s');
  print('');
}

void _benchmarkDecode(String name, String encoded, int iterations) {
  final stopwatch = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    percent.decode(encoded);
  }

  stopwatch.stop();
  final totalMs = stopwatch.elapsedMilliseconds;
  final avgMs = totalMs / iterations;

  print('$name:');
  print('  总时间: ${totalMs}ms');
  print('  平均时间: ${avgMs.toStringAsFixed(3)}ms');
  print('');
}

void _benchmarkRoundTrip(String name, List<int> data, int iterations) {
  final stopwatch = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    final encoded = percent.encode(data);
    percent.decode(encoded);
  }

  stopwatch.stop();
  final totalMs = stopwatch.elapsedMilliseconds;
  final avgMs = totalMs / iterations;
  final throughput =
      (data.length * iterations) / (totalMs / 1000) / 1024 / 1024;

  print('$name:');
  print('  总时间: ${totalMs}ms');
  print('  平均时间: ${avgMs.toStringAsFixed(3)}ms');
  print('  吞吐量: ${throughput.toStringAsFixed(2)} MB/s');
  print('');
}
