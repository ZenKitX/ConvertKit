// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:convert_kit/convert_kit.dart';

/// 百分号编解码性能基准测试
void main() {
  print('=== 百分号编解码性能基准测试 ===\n');

  // 测试数据 - 包含需要编码的字符（使用 UTF-8 编码）
  final smallData = 'Hello World! @#\$%^&*()'.codeUnits;
  final mediumData = List.generate(
    1000,
    (i) => 'Test String ${i} with special chars: @#\$%^&*() test\n'.codeUnits,
  ).expand((x) => x).toList();
  final largeData = List.generate(
    10000,
    (i) => 'Data ${i}: ABCabc123 !@#\$%^&*()_+-=[]{}|;:,.<>? data\n'.codeUnits,
  ).expand((x) => x).toList();

  // 编码基准测试
  print('--- 编码性能 ---');
  _benchmarkEncode('小数据 (~50 字节)', smallData, 10000);
  _benchmarkEncode('中等数据 (~50KB)', mediumData, 1000);
  _benchmarkEncode('大数据 (~500KB)', largeData, 100);

  print('\n--- 解码性能 ---');
  final smallEncoded = percent.encode(smallData);
  final mediumEncoded = percent.encode(mediumData);
  final largeEncoded = percent.encode(largeData);

  _benchmarkDecode('小数据 (~50 字节)', smallEncoded, 10000);
  _benchmarkDecode('中等数据 (~50KB)', mediumEncoded, 1000);
  _benchmarkDecode('大数据 (~500KB)', largeEncoded, 100);

  print('\n--- 往返转换性能 ---');
  _benchmarkRoundTrip('小数据 (~50 字节)', smallData, 10000);
  _benchmarkRoundTrip('中等数据 (~50KB)', mediumData, 1000);
  _benchmarkRoundTrip('大数据 (~500KB)', largeData, 100);
}

void _benchmarkEncode(String name, List<int> data, int iterations) {
  final stopwatch = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    percent.encode(data);
  }

  stopwatch.stop();
  final totalMs = stopwatch.elapsedMilliseconds;
  final avgMs = totalMs / iterations;
  final throughput = (data.length * iterations) / (totalMs / 1000) / 1024 / 1024;

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
  // 估算原始数据大小（编码后会变大）
  final estimatedSize = encoded.length * 0.7; // 粗略估计
  final throughput = (estimatedSize * iterations) / (totalMs / 1000) / 1024 / 1024;

  print('$name:');
  print('  总时间: ${totalMs}ms');
  print('  平均时间: ${avgMs.toStringAsFixed(3)}ms');
  print('  吞吐量: ${throughput.toStringAsFixed(2)} MB/s');
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
  final throughput = (data.length * iterations) / (totalMs / 1000) / 1024 / 1024;

  print('$name:');
  print('  总时间: ${totalMs}ms');
  print('  平均时间: ${avgMs.toStringAsFixed(3)}ms');
  print('  吞吐量: ${throughput.toStringAsFixed(2)} MB/s');
  print('');
}
