// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:convert_kit/convert_kit.dart';

void main() {
  print('=== ConvertKit 示例 ===\n');

  // 十六进制编解码示例
  hexExample();

  // 百分号编码示例
  percentExample();

  // 身份编解码器示例
  identityExample();

  // 累加器示例
  accumulatorExample();
}

/// 十六进制编解码示例
void hexExample() {
  print('--- 十六进制编解码 ---');

  // 编码字节数组为十六进制字符串
  final bytes = [255, 254, 253, 72, 101, 108, 108, 111];
  final hexString = hex.encode(bytes);
  print('编码: $bytes -> $hexString');

  // 解码十六进制字符串为字节数组
  final decoded = hex.decode('48656c6c6f');
  print('解码: 48656c6c6f -> $decoded');
  print('解码为字符串: ${String.fromCharCodes(decoded)}');

  print('');
}

/// 百分号编码示例
void percentExample() {
  print('--- 百分号编码 ---');

  // 编码字节数组（URL 编码）
  final text = 'Hello World!';
  final bytes = text.codeUnits;
  final encoded = percent.encode(bytes);
  print('编码: $text -> $encoded');

  // 解码百分号编码字符串
  final decoded = percent.decode('Hello%20World%21');
  print('解码: Hello%20World%21 -> ${String.fromCharCodes(decoded)}');

  // 编码中文（需要先转换为 UTF-8 字节）
  final chineseBytes = utf8.encode('你好世界');
  final chineseEncoded = percent.encode(chineseBytes);
  print('中文编码: 你好世界 -> $chineseEncoded');

  print('');
}

/// 身份编解码器示例
void identityExample() {
  print('--- 身份编解码器 ---');

  // 身份编解码器不做任何转换
  final identity = IdentityCodec<String>();
  final input = 'Hello';
  final encoded = identity.encode(input);
  final decoded = identity.decode(encoded);

  print('输入: $input');
  print('编码: $encoded');
  print('解码: $decoded');
  print('相同: ${input == decoded}');

  print('');
}

/// 累加器示例
void accumulatorExample() {
  print('--- 累加器 ---');

  // 字节累加器
  final byteSink = ByteAccumulatorSink();
  byteSink.add([72, 101]);
  byteSink.add([108, 108, 111]);
  print('字节累加: ${byteSink.bytes}');
  print('字节累加为字符串: ${String.fromCharCodes(byteSink.bytes)}');

  // 字符串累加器
  final stringSink = StringAccumulatorSink();
  stringSink.add('Hello');
  stringSink.add(' ');
  stringSink.add('World');
  print('字符串累加: ${stringSink.string}');

  print('');
}
