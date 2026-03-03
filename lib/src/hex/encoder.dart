// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import '../charcodes.dart';

/// [HexEncoder] 的规范实例。
const hexEncoder = HexEncoder._();

/// 十六进制编码器，将字节数组编码为十六进制字符串。
///
/// 将每个字节（0-255）转换为两个十六进制字符（00-ff）。
/// 使用小写字母 a-f 表示 10-15。
///
/// ## 编码规则
///
/// - 每个字节编码为 2 个十六进制字符
/// - 使用小写字母（a-f）
/// - 不添加任何分隔符或前缀
///
/// ## 使用示例
///
/// ```dart
/// final encoder = HexEncoder();
///
/// // 编码字节数组
/// final encoded = encoder.convert([255, 254, 253]);
/// print(encoded); // "fffefd"
///
/// // 编码空数组
/// print(encoder.convert([])); // ""
///
/// // 编码单个字节
/// print(encoder.convert([0])); // "00"
/// print(encoder.convert([255])); // "ff"
/// ```
///
/// ## 分块转换
///
/// 支持流式编码大量数据：
///
/// ```dart
/// final sink = StringBuffer();
/// final conversionSink = hexEncoder.startChunkedConversion(
///   StringConversionSink.fromStringSink(sink),
/// );
///
/// conversionSink.add([1, 2, 3]);
/// conversionSink.add([4, 5, 6]);
/// conversionSink.close();
///
/// print(sink.toString()); // "010203040506"
/// ```
///
/// ## 异常
///
/// 如果输入包含不在 0-255 范围内的值，抛出 [FormatException]。
///
/// ## 性能说明
///
/// - 使用 [Uint8List] 作为中间缓冲区，避免字符串拼接
/// - 使用位运算优化字节到十六进制的转换
/// - 时间复杂度：O(n)，其中 n 为输入字节数
/// - 空间复杂度：O(n)，输出长度为输入的 2 倍
class HexEncoder extends Converter<List<int>, String> {
  /// 创建一个十六进制编码器。
  const HexEncoder._();

  /// 将字节数组转换为十六进制字符串。
  ///
  /// 将 [input] 中的每个字节编码为两个十六进制字符。
  ///
  /// ## 参数
  ///
  /// - [input]: 要编码的字节数组
  ///
  /// ## 返回值
  ///
  /// 十六进制字符串，长度为输入长度的 2 倍。
  ///
  /// ## 异常
  ///
  /// 如果 [input] 包含不在 0-255 范围内的值，抛出 [FormatException]。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final encoder = hexEncoder;
  /// print(encoder.convert([10, 20, 30])); // "0a141e"
  /// ```
  @override
  String convert(List<int> input) => _convert(input, 0, input.length);

  /// 开始分块转换。
  ///
  /// 返回一个 [ByteConversionSink]，可以分块添加字节数据。
  /// 编码后的字符串会传递给 [sink]。
  ///
  /// ## 参数
  ///
  /// - [sink]: 接收编码结果的 sink
  ///
  /// ## 返回值
  ///
  /// 用于接收输入字节的 [ByteConversionSink]。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final output = StringBuffer();
  /// final conversionSink = hexEncoder.startChunkedConversion(
  ///   StringConversionSink.fromStringSink(output),
  /// );
  ///
  /// conversionSink.add([1, 2]);
  /// conversionSink.add([3, 4]);
  /// conversionSink.close();
  ///
  /// print(output); // "01020304"
  /// ```
  @override
  ByteConversionSink startChunkedConversion(Sink<String> sink) =>
      _HexEncoderSink(sink);
}

/// 分块十六进制编码的转换 sink。
///
/// 内部类，用于支持 [HexEncoder] 的分块转换。
class _HexEncoderSink extends ByteConversionSinkBase {
  /// 接收编码结果的底层 sink。
  final Sink<String> _sink;

  /// 创建一个十六进制编码 sink。
  _HexEncoderSink(this._sink);

  @override
  void add(List<int> chunk) {
    _sink.add(_convert(chunk, 0, chunk.length));
  }

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, chunk.length);
    _sink.add(_convert(chunk, start, end));
    if (isLast) _sink.close();
  }

  @override
  void close() {
    _sink.close();
  }
}

/// 将字节数组的指定范围转换为十六进制字符串。
///
/// 这是核心转换函数，被 [HexEncoder] 和 [_HexEncoderSink] 使用。
///
/// ## 参数
///
/// - [bytes]: 源字节数组
/// - [start]: 起始位置（包含）
/// - [end]: 结束位置（不包含）
///
/// ## 返回值
///
/// 十六进制字符串。
///
/// ## 实现说明
///
/// 使用 [Uint8List] 作为缓冲区比 [StringBuffer] 更高效，
/// 因为我们知道只会生成 ASCII 字符，并且提前知道长度。
///
/// 使用位运算 OR 检测无效字节，避免在主循环中添加额外分支。
String _convert(List<int> bytes, int start, int end) {
  // 使用 Uint8List 作为缓冲区，比 StringBuffer 更高效
  // 因为我们知道只生成 ASCII 字符，且提前知道长度
  final buffer = Uint8List((end - start) * 2);
  var bufferIndex = 0;

  // 对所有字节进行位运算 OR
  // 这样可以在不增加主循环分支的情况下检测越界字节
  var byteOr = 0;
  for (var i = start; i < end; i++) {
    final byte = bytes[i];
    byteOr |= byte;

    // 位运算等价于 `byte ~/ 16` 和 `byte % 16`
    // 但对于 dart2js 更容易优化，因为它无法证明 byte 总是正数
    buffer[bufferIndex++] = _codeUnitForDigit((byte & 0xF0) >> 4);
    buffer[bufferIndex++] = _codeUnitForDigit(byte & 0x0F);
  }

  // 如果所有字节都在有效范围内，直接返回结果
  if (byteOr >= 0 && byteOr <= 255) {
    return String.fromCharCodes(buffer);
  }

  // 如果有无效字节，找到它并抛出异常
  for (var i = start; i < end; i++) {
    final byte = bytes[i];
    if (byte >= 0 && byte <= 0xff) continue;
    throw FormatException(
      '无效的字节值 ${byte < 0 ? "-" : ""}0x${byte.abs().toRadixString(16)}',
      bytes,
      i,
    );
  }

  throw StateError('不可达代码');
}

/// 返回十六进制数字对应的 ASCII/Unicode 码点。
///
/// 将 0-15 的数字转换为对应的十六进制字符：
/// - 0-9 → '0'-'9' (0x30-0x39)
/// - 10-15 → 'a'-'f' (0x61-0x66)
///
/// ## 参数
///
/// - [digit]: 0-15 之间的数字
///
/// ## 返回值
///
/// 对应的字符码点。
int _codeUnitForDigit(int digit) => digit < 10 ? digit + $0 : digit + $a - 10;
