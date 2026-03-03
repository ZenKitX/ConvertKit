// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import '../utils.dart';

/// [HexDecoder] 的规范实例。
const hexDecoder = HexDecoder._();

/// 十六进制解码器，将十六进制字符串解码为字节数组。
///
/// 将每两个十六进制字符解码为一个字节（0-255）。
/// 支持大小写混合的十六进制字符。
///
/// ## 解码规则
///
/// - 每 2 个十六进制字符解码为 1 个字节
/// - 支持大写（A-F）和小写（a-f）字母
/// - 输入长度必须为偶数
/// - 只接受有效的十六进制字符（0-9, A-F, a-f）
///
/// ## 使用示例
///
/// ```dart
/// final decoder = HexDecoder();
///
/// // 解码十六进制字符串
/// final decoded = decoder.convert('fffefd');
/// print(decoded); // [255, 254, 253]
///
/// // 支持大小写混合
/// print(decoder.convert('FfFeFd')); // [255, 254, 253]
///
/// // 解码空字符串
/// print(decoder.convert('')); // []
/// ```
///
/// ## 分块转换
///
/// 支持流式解码大量数据，可以处理跨块的字节边界：
///
/// ```dart
/// final sink = ByteAccumulatorSink();
/// final conversionSink = hexDecoder.startChunkedConversion(sink);
///
/// // 可以在奇数位置分块
/// conversionSink.add('010');
/// conversionSink.add('203');
/// conversionSink.close();
///
/// print(sink.bytes); // [1, 2, 3]
/// ```
///
/// ## 异常
///
/// - 如果输入长度为奇数，抛出 [FormatException]
/// - 如果包含非十六进制字符，抛出 [FormatException]
/// - 如果分块转换在奇数位置结束，抛出 [FormatException]
///
/// ## 性能说明
///
/// - 直接解码到 [Uint8List]，避免中间转换
/// - 使用位运算优化十六进制到字节的转换
/// - 时间复杂度：O(n)，其中 n 为输入字符数
/// - 空间复杂度：O(n/2)，输出长度为输入的一半
class HexDecoder extends Converter<String, List<int>> {
  /// 创建一个十六进制解码器。
  const HexDecoder._();

  /// 将十六进制字符串转换为字节数组。
  ///
  /// 将 [input] 中的每两个十六进制字符解码为一个字节。
  ///
  /// ## 参数
  ///
  /// - [input]: 要解码的十六进制字符串
  ///
  /// ## 返回值
  ///
  /// [Uint8List]，长度为输入长度的一半。
  ///
  /// ## 异常
  ///
  /// - 如果 [input] 长度为奇数，抛出 [FormatException]
  /// - 如果 [input] 包含非十六进制字符，抛出 [FormatException]
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final decoder = hexDecoder;
  /// print(decoder.convert('0a141e')); // [10, 20, 30]
  /// print(decoder.convert('ABCDEF')); // [171, 205, 239]
  /// ```
  @override
  Uint8List convert(String input) {
    if (!input.length.isEven) {
      throw FormatException(
        '输入长度无效，必须为偶数',
        input,
        input.length,
      );
    }

    final bytes = Uint8List(input.length ~/ 2);
    _decode(input.codeUnits, 0, input.length, bytes, 0);
    return bytes;
  }

  /// 开始分块转换。
  ///
  /// 返回一个 [StringConversionSink]，可以分块添加十六进制字符串。
  /// 解码后的字节数组会传递给 [sink]。
  ///
  /// 支持在奇数位置分块，会自动处理跨块的字节边界。
  ///
  /// ## 参数
  ///
  /// - [sink]: 接收解码结果的 sink
  ///
  /// ## 返回值
  ///
  /// 用于接收输入字符串的 [StringConversionSink]。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final output = ByteAccumulatorSink();
  /// final conversionSink = hexDecoder.startChunkedConversion(output);
  ///
  /// conversionSink.add('0102');
  /// conversionSink.add('0304');
  /// conversionSink.close();
  ///
  /// print(output.bytes); // [1, 2, 3, 4]
  /// ```
  @override
  StringConversionSink startChunkedConversion(Sink<List<int>> sink) =>
      _HexDecoderSink(sink);
}

/// 分块十六进制解码的转换 sink。
///
/// 内部类，用于支持 [HexDecoder] 的分块转换。
/// 可以处理跨块的字节边界。
class _HexDecoderSink extends StringConversionSinkBase {
  /// 接收解码结果的底层 sink。
  final Sink<List<int>> _sink;

  /// 上一个字符串的尾部数字。
  ///
  /// 如果最近的字符串有奇数个十六进制字符，这将是非 null。
  /// 由于它是高位数字，总是 16 的倍数。
  int? _lastDigit;

  /// 创建一个十六进制解码 sink。
  _HexDecoderSink(this._sink);

  @override
  void addSlice(String string, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, string.length);

    if (start == end) {
      if (isLast) _close(string, end);
      return;
    }

    final codeUnits = string.codeUnits;
    Uint8List bytes;
    int bytesStart;

    if (_lastDigit == null) {
      // 没有遗留数字，正常解码
      bytes = Uint8List((end - start) ~/ 2);
      bytesStart = 0;
    } else {
      // 有遗留数字，先与第一个字符组合
      final hexPairs = (end - start - 1) ~/ 2;
      bytes = Uint8List(1 + hexPairs);
      bytes[0] = _lastDigit! + digitForCodeUnit(codeUnits, start);
      start++;
      bytesStart = 1;
    }

    _lastDigit = _decode(codeUnits, start, end, bytes, bytesStart);

    _sink.add(bytes);
    if (isLast) _close(string, end);
  }

  @override
  ByteConversionSink asUtf8Sink(bool allowMalformed) =>
      _HexDecoderByteSink(_sink);

  @override
  void close() => _close();

  /// 类似 [close]，但在抛出 [FormatException] 时包含 [string] 和 [index]。
  void _close([String? string, int? index]) {
    if (_lastDigit != null) {
      throw FormatException(
        '输入以不完整的编码字节结束',
        string,
        index,
      );
    }

    _sink.close();
  }
}

/// 从 UTF-8 字节进行分块十六进制解码的转换 sink。
///
/// 内部类，用于支持从字节流解码十六进制。
class _HexDecoderByteSink extends ByteConversionSinkBase {
  /// 接收解码结果的底层 sink。
  final Sink<List<int>> _sink;

  /// 上一个字符串的尾部数字。
  ///
  /// 如果最近的字符串有奇数个十六进制字符，这将是非 null。
  /// 由于它是高位数字，总是 16 的倍数。
  int? _lastDigit;

  /// 创建一个十六进制解码字节 sink。
  _HexDecoderByteSink(this._sink);

  @override
  void add(List<int> chunk) => addSlice(chunk, 0, chunk.length, false);

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, chunk.length);

    if (start == end) {
      if (isLast) _close(chunk, end);
      return;
    }

    Uint8List bytes;
    int bytesStart;

    if (_lastDigit == null) {
      bytes = Uint8List((end - start) ~/ 2);
      bytesStart = 0;
    } else {
      final hexPairs = (end - start - 1) ~/ 2;
      bytes = Uint8List(1 + hexPairs);
      bytes[0] = _lastDigit! + digitForCodeUnit(chunk, start);
      start++;
      bytesStart = 1;
    }

    _lastDigit = _decode(chunk, start, end, bytes, bytesStart);

    _sink.add(bytes);
    if (isLast) _close(chunk, end);
  }

  @override
  void close() => _close();

  /// 类似 [close]，但在抛出 [FormatException] 时包含 [chunk] 和 [index]。
  void _close([List<int>? chunk, int? index]) {
    if (_lastDigit != null) {
      throw FormatException(
        '输入以不完整的编码字节结束',
        chunk,
        index,
      );
    }

    _sink.close();
  }
}

/// 解码 [codeUnits] 并将结果写入 [destination]。
///
/// 从 [codeUnits] 的 [sourceStart] 到 [sourceEnd] 读取。
/// 将结果写入 [destination]，从 [destinationStart] 开始。
///
/// 如果解码结束时有剩余数字，返回该数字。否则返回 null。
///
/// ## 参数
///
/// - [codeUnits]: 源字符编码列表
/// - [sourceStart]: 源起始位置
/// - [sourceEnd]: 源结束位置
/// - [destination]: 目标字节数组
/// - [destinationStart]: 目标起始位置
///
/// ## 返回值
///
/// 如果有剩余数字，返回该数字（16 的倍数）；否则返回 null。
int? _decode(
  List<int> codeUnits,
  int sourceStart,
  int sourceEnd,
  List<int> destination,
  int destinationStart,
) {
  var destinationIndex = destinationStart;

  // 每次处理两个十六进制字符
  for (var i = sourceStart; i < sourceEnd - 1; i += 2) {
    final firstDigit = digitForCodeUnit(codeUnits, i);
    final secondDigit = digitForCodeUnit(codeUnits, i + 1);
    destination[destinationIndex++] = 16 * firstDigit + secondDigit;
  }

  // 如果有剩余的单个字符，返回它（作为高位数字）
  if ((sourceEnd - sourceStart).isEven) return null;
  return 16 * digitForCodeUnit(codeUnits, sourceEnd - 1);
}
