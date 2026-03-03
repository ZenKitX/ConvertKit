// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import '../charcodes.dart';

/// [PercentEncoder] 的规范实例。
const percentEncoder = PercentEncoder._();

/// 百分号编码器，将字节数组编码为百分号编码（URL 编码）字符串。
///
/// 遵循 [RFC 3986](https://tools.ietf.org/html/rfc3986#section-2.1) 规范。
///
/// ## 编码规则
///
/// 保留以下字符不编码（unreserved characters）：
/// - ASCII 字母：A-Z, a-z
/// - 数字：0-9
/// - 特殊字符：`-`, `.`, `_`, `~`
///
/// 其他所有字节都编码为 `%XX` 格式，其中 XX 是两位大写十六进制数。
///
/// ## 与 Uri.encodeQueryComponent 的区别
///
/// - 本编码器不将空格（0x20）编码为 `+`
/// - 空格编码为 `%20`
///
/// ## 使用示例
///
/// ```dart
/// final encoder = PercentEncoder();
///
/// // 编码字节数组
/// final encoded = encoder.convert([65, 66, 67, 32, 49, 50, 51]);
/// print(encoded); // "ABC%20123"
///
/// // 编码特殊字符
/// final special = encoder.convert([64, 33, 40]); // @!(
/// print(special); // "%40%21%28"
///
/// // 保留字符不编码
/// final unreserved = encoder.convert([45, 46, 95, 126]); // -._~
/// print(unreserved); // "-._~"
/// ```
///
/// ## 分块转换
///
/// ```dart
/// final sink = StringBuffer();
/// final conversionSink = percentEncoder.startChunkedConversion(
///   StringConversionSink.fromStringSink(sink),
/// );
///
/// conversionSink.add([65, 66, 67]);
/// conversionSink.add([32, 49, 50, 51]);
/// conversionSink.close();
///
/// print(sink.toString()); // "ABC%20123"
/// ```
///
/// ## 异常
///
/// 如果输入包含不在 0-255 范围内的值，抛出 [FormatException]。
///
/// ## 性能说明
///
/// - 使用 [StringBuffer] 构建结果字符串
/// - 使用位运算优化字节检查
/// - 时间复杂度：O(n)，其中 n 为输入字节数
class PercentEncoder extends Converter<List<int>, String> {
  /// 创建一个百分号编码器。
  const PercentEncoder._();

  /// 将字节数组转换为百分号编码字符串。
  ///
  /// 将 [input] 中的每个字节编码为百分号编码格式。
  /// 保留字符（字母、数字、`-._~`）不编码，其他字节编码为 `%XX`。
  ///
  /// ## 参数
  ///
  /// - [input]: 要编码的字节数组
  ///
  /// ## 返回值
  ///
  /// 百分号编码的字符串。
  ///
  /// ## 异常
  ///
  /// 如果 [input] 包含不在 0-255 范围内的值，抛出 [FormatException]。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final encoder = percentEncoder;
  /// print(encoder.convert([72, 101, 108, 108, 111])); // "Hello"
  /// print(encoder.convert([32, 64, 33])); // "%20%40%21"
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
  /// final conversionSink = percentEncoder.startChunkedConversion(
  ///   StringConversionSink.fromStringSink(output),
  /// );
  ///
  /// conversionSink.add([65, 66]);
  /// conversionSink.add([32, 67]);
  /// conversionSink.close();
  ///
  /// print(output); // "AB%20C"
  /// ```
  @override
  ByteConversionSink startChunkedConversion(Sink<String> sink) =>
      _PercentEncoderSink(sink);
}

/// 分块百分号编码的转换 sink。
///
/// 内部类，用于支持 [PercentEncoder] 的分块转换。
class _PercentEncoderSink extends ByteConversionSinkBase {
  /// 接收编码结果的底层 sink。
  final Sink<String> _sink;

  /// 创建一个百分号编码 sink。
  _PercentEncoderSink(this._sink);

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

/// 将字节数组的指定范围转换为百分号编码字符串。
///
/// 这是核心转换函数，被 [PercentEncoder] 和 [_PercentEncoderSink] 使用。
///
/// ## 参数
///
/// - [bytes]: 源字节数组
/// - [start]: 起始位置（包含）
/// - [end]: 结束位置（不包含）
///
/// ## 返回值
///
/// 百分号编码的字符串。
///
/// ## 实现说明
///
/// 使用 [StringBuffer] 构建结果，对于保留字符直接写入，
/// 其他字符编码为 `%XX` 格式。
String _convert(List<int> bytes, int start, int end) {
  final buffer = StringBuffer();

  // 对所有字节进行位运算 OR
  // 这样可以在不增加主循环分支的情况下检测越界字节
  var byteOr = 0;

  for (var i = start; i < end; i++) {
    final byte = bytes[i];
    byteOr |= byte;

    // 如果字节是大写字母，转换为小写以检查是否为保留字符
    // 这是因为 ASCII 中大写字母比小写字母小 0x20
    // 通过 OR 0x20 确保字母是小写
    final letter = 0x20 | byte;

    if ((letter >= $a && letter <= $z) || // 字母
        (byte >= $0 && byte <= $9) || // 数字
        byte == $dash || // -
        byte == $dot || // .
        byte == $underscore || // _
        byte == $tilde) {
      // ~
      // 保留字符直接写入
      buffer.writeCharCode(byte);
      continue;
    }

    // 其他字符编码为 %XX
    buffer.writeCharCode($percent);

    // 位运算等价于 `byte ~/ 16` 和 `byte % 16`
    // 但对于 dart2js 更容易优化
    buffer.writeCharCode(_codeUnitForDigit((byte & 0xF0) >> 4));
    buffer.writeCharCode(_codeUnitForDigit(byte & 0x0F));
  }

  // 如果所有字节都在有效范围内，直接返回结果
  if (byteOr >= 0 && byteOr <= 255) {
    return buffer.toString();
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

/// 返回十六进制数字对应的 ASCII/Unicode 码点（大写）。
///
/// 将 0-15 的数字转换为对应的十六进制字符：
/// - 0-9 → '0'-'9' (0x30-0x39)
/// - 10-15 → 'A'-'F' (0x41-0x46)
///
/// ## 参数
///
/// - [digit]: 0-15 之间的数字
///
/// ## 返回值
///
/// 对应的大写字符码点。
int _codeUnitForDigit(int digit) => digit < 10 ? digit + $0 : digit + $A - 10;
