// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:convert_kit/convert_kit.dart';

/// 十六进制编解码性能基准测试
void main() {
  print('=== 十六进制编解码性能基准测试 ===\n');

  // 测试数据
  final smallData = List.generate(100, (i) => i % 256);
  final mediumData = List.generate(10000, (i) => i % 256);
  final largeData = List.generate(1000000, (i) => i % 256);

  // 编码基准测试
  print('--- 编码性能 ---');
  _benchmarkEncode('小数据 (100 字节)', smallData, 10000);
  _benchmarkEncode('中等数据 (10KB)', mediumData, 1000);
  _benchmarkEncode('大数据 (1MB)', largeData, 10);

  print('\n--- 解码性能 ---');
  final smallHex = hex.encode(smallData);
  final mediumHex = hex.encode(mediumData);
  final largeHex = hex.encode(largeData);

  _benchmarkDecode('小数据 (100 字节)', smallHex, 10000);
  _benchmarkDecode('中等数据 (10KB)', mediumHex, 1000);
  _benchmarkDecode('大数据 (1MB)', largeHex, 10);

  print('\n--- 往返转换性能 ---');
  _benchmarkRoundTrip('小数据 (100 字节)', smallData, 10000);
  _benchmarkRoundTrip('中等数据 (10KB)', mediumData, 1000);
  _benchmarkRoundTrip('大数据 (1MB)', largeData, 10);
}

void _benchmarkEncode(String name, List<int> data, int iterations) {
  final stopwatch = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    hex.encode(data);
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

void _benchmarkDecode(String name, String hexString, int iterations) {
  final stopwatch = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    hex.decode(hexString);
  }

  stopwatch.stop();
  final totalMs = stopwatch.elapsedMilliseconds;
  final avgMs = totalMs / iterations;
  final throughput =
      (hexString.length / 2 * iterations) / (totalMs / 1000) / 1024 / 1024;

  print('$name:');
  print('  总时间: ${totalMs}ms');
  print('  平均时间: ${avgMs.toStringAsFixed(3)}ms');
  print('  吞吐量: ${throughput.toStringAsFixed(2)} MB/s');
  print('');
}

void _benchmarkRoundTrip(String name, List<int> data, int iterations) {
  final stopwatch = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    final encoded = hex.encode(data);
    hex.decode(encoded);
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
