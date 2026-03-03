// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:typed_data/typed_data.dart';

import '../charcodes.dart';
import '../utils.dart';

/// [PercentDecoder] 的规范实例。
const percentDecoder = PercentDecoder._();

/// 表示上一个字符是 `%` 的特殊标记。
const _lastPercent = -1;

/// 百分号解码器，将百分号编码（URL 编码）字符串解码为字节数组。
///
/// 遵循 [RFC 3986](https://tools.ietf.org/html/rfc3986#section-2.1) 规范。
///
/// ## 解码规则
///
/// - 将 `%XX` 格式解码为对应的字节（XX 为两位十六进制数）
/// - 支持大小写十六进制字母（A-F 或 a-f）
/// - 非百分号编码的字节直接保留
/// - 默认将 `+` 解释为 `0x2B`（而非空格 `0x20`）
///
/// ## 与 Uri.decodeQueryComponent 的区别
///
/// - 本解码器不将 `+` 解码为空格
/// - `+` 保持为 `0x2B`
///
/// ## 使用示例
///
/// ```dart
/// final decoder = PercentDecoder();
///
/// // 解码百分号编码字符串
/// final decoded = decoder.convert('ABC%20123');
/// print(decoded); // [65, 66, 67, 32, 49, 50, 51]
///
/// // 解码特殊字符
/// final special = decoder.convert('%40%21%28'); // @!(
/// print(special); // [64, 33, 40]
///
/// // 支持大小写混合
/// final mixed = decoder.convert('%2b%2B'); // ++
/// print(mixed); // [43, 43]
/// ```
///
/// ## 分块转换
///
/// ```dart
/// final results = <List<int>>[];
/// final controller = StreamController<List<int>>(sync: true);
/// controller.stream.listen(results.add);
///
/// final sink = percentDecoder.startChunkedConversion(controller.sink);
/// sink.add('ABC%20');
/// sink.add('123');
/// sink.close();
///
/// print(results); // [[65, 66, 67, 32], [49, 50, 51]]
/// ```
///
/// ## 异常
///
/// - 如果输入以不完整的百分号编码结尾（如 `%2`），抛出 [FormatException]
/// - 如果输入包含非 ASCII 字符，抛出 [FormatException]
/// - 如果百分号后不是有效的十六进制数字，抛出 [FormatException]
///
/// ## 性能说明
///
/// - 使用 [Uint8Buffer] 高效构建结果
/// - 批量复制连续的非编码字节
/// - 时间复杂度：O(n)，其中 n 为输入字符串长度
class PercentDecoder extends Converter<String, List<int>> {
  /// 创建一个百分号解码器。
  const PercentDecoder._();

  /// 将百分号编码字符串转换为字节数组。
  ///
  /// 将 [input] 中的百分号编码（`%XX`）解码为对应的字节。
  /// 非编码字符直接转换为对应的字节值。
  ///
  /// ## 参数
  ///
  /// - [input]: 要解码的百分号编码字符串
  ///
  /// ## 返回值
  ///
  /// 解码后的字节数组。
  ///
  /// ## 异常
  ///
  /// - 如果 [input] 以不完整的百分号编码结尾，抛出 [FormatException]
  /// - 如果 [input] 包含非 ASCII 字符，抛出 [FormatException]
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final decoder = percentDecoder;
  /// print(decoder.convert('Hello')); // [72, 101, 108, 108, 111]
  /// print(decoder.convert('%20%40%21')); // [32, 64, 33]
  /// ```
  @override
  List<int> convert(String input) {
    final buffer = Uint8Buffer();
    final lastDigit = _decode(input.codeUnits, 0, input.length, buffer);

    if (lastDigit != null) {
      throw FormatException(
        '输入以不完整的编码字节结尾',
        input,
        input.length,
      );
    }

    return buffer.buffer.asUint8List(0, buffer.length);
  }

  /// 开始分块转换。
  ///
  /// 返回一个 [StringConversionSink]，可以分块添加字符串数据。
  /// 解码后的字节数组会传递给 [sink]。
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
  /// final output = <List<int>>[];
  /// final controller = StreamController<List<int>>(sync: true);
  /// controller.stream.listen(output.add);
  ///
  /// final conversionSink = percentDecoder.startChunkedConversion(
  ///   controller.sink,
  /// );
  ///
  /// conversionSink.add('AB%');
  /// conversionSink.add('20C');
  /// conversionSink.close();
  ///
  /// print(output); // [[65, 66], [32, 67]]
  /// ```
  @override
  StringConversionSink startChunkedConversion(Sink<List<int>> sink) =>
      _PercentDecoderSink(sink);
}

/// 分块百分号解码的转换 sink。
///
/// 内部类，用于支持 [PercentDecoder] 的分块转换。
/// 可以处理跨块分割的百分号编码。
class _PercentDecoderSink extends StringConversionSinkBase {
  /// 接收解码结果的底层 sink。
  final Sink<List<int>> _sink;

  /// 上一个字符串的尾部数字。
  ///
  /// - `null`: 上一个字符串以完整的百分号编码字节或字面字符结尾
  /// - [_lastPercent]: 上一个字符串以 `%` 结尾
  /// - 其他值: 上一个字符串以 `%` 后跟一个十六进制数字结尾，
  ///   这是该数字（作为高位数字，总是 16 的倍数）
  int? _lastDigit;

  /// 创建一个百分号解码 sink。
  _PercentDecoderSink(this._sink);

  @override
  void addSlice(String string, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, string.length);

    if (start == end) {
      if (isLast) _close(string, end);
      return;
    }

    final buffer = Uint8Buffer();
    final codeUnits = string.codeUnits;

    // 如果上一个块以 % 结尾，当前块的第一个字符应该是第一个十六进制数字
    if (_lastDigit == _lastPercent) {
      _lastDigit = 16 * digitForCodeUnit(codeUnits, start);
      start++;

      if (start == end) {
        if (isLast) _close(string, end);
        return;
      }
    }

    // 如果上一个块以 %X 结尾，当前块的第一个字符应该是第二个十六进制数字
    if (_lastDigit != null) {
      buffer.add(_lastDigit! + digitForCodeUnit(codeUnits, start));
      start++;
    }

    _lastDigit = _decode(codeUnits, start, end, buffer);

    _sink.add(buffer.buffer.asUint8List(0, buffer.length));
    if (isLast) _close(string, end);
  }

  @override
  ByteConversionSink asUtf8Sink(bool allowMalformed) =>
      _PercentDecoderByteSink(_sink);

  @override
  void close() => _close();

  /// 类似 [close]，但在抛出 [FormatException] 时包含 [string] 和 [index]。
  void _close([String? string, int? index]) {
    if (_lastDigit != null) {
      throw FormatException(
        '输入以不完整的编码字节结尾',
        string,
        index,
      );
    }

    _sink.close();
  }
}

/// 从 UTF-8 字节进行分块百分号解码的转换 sink。
///
/// 内部类，用于支持从 UTF-8 字节流解码百分号编码。
class _PercentDecoderByteSink extends ByteConversionSinkBase {
  /// 接收解码结果的底层 sink。
  final Sink<List<int>> _sink;

  /// 上一个字符串的尾部数字。
  ///
  /// - `null`: 上一个字符串以完整的百分号编码字节或字面字符结尾
  /// - [_lastPercent]: 上一个字符串以 `%` 结尾
  /// - 其他值: 上一个字符串以 `%` 后跟一个十六进制数字结尾，
  ///   这是该数字（作为高位数字，总是 16 的倍数）
  int? _lastDigit;

  /// 创建一个百分号解码字节 sink。
  _PercentDecoderByteSink(this._sink);

  @override
  void add(List<int> chunk) => addSlice(chunk, 0, chunk.length, false);

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, chunk.length);

    if (start == end) {
      if (isLast) _close(chunk, end);
      return;
    }

    final buffer = Uint8Buffer();

    // 如果上一个块以 % 结尾，当前块的第一个字节应该是第一个十六进制数字
    if (_lastDigit == _lastPercent) {
      _lastDigit = 16 * digitForCodeUnit(chunk, start);
      start++;

      if (start == end) {
        if (isLast) _close(chunk, end);
        return;
      }
    }

    // 如果上一个块以 %X 结尾，当前块的第一个字节应该是第二个十六进制数字
    if (_lastDigit != null) {
      buffer.add(_lastDigit! + digitForCodeUnit(chunk, start));
      start++;
    }

    _lastDigit = _decode(chunk, start, end, buffer);

    _sink.add(buffer.buffer.asUint8List(0, buffer.length));
    if (isLast) _close(chunk, end);
  }

  @override
  void close() => _close();

  /// 类似 [close]，但在抛出 [FormatException] 时包含 [chunk] 和 [index]。
  void _close([List<int>? chunk, int? index]) {
    if (_lastDigit != null) {
      throw FormatException(
        '输入以不完整的编码字节结尾',
        chunk,
        index,
      );
    }

    _sink.close();
  }
}

/// 解码 [codeUnits] 并将结果写入 [buffer]。
///
/// 从 [codeUnits] 的 [start] 到 [end] 之间读取数据。
/// 将结果写入 [buffer]。
///
/// 如果解码结束时有剩余的数字，返回该数字。
/// 否则返回 `null`。
///
/// ## 参数
///
/// - [codeUnits]: 源码点数组
/// - [start]: 起始位置（包含）
/// - [end]: 结束位置（不包含）
/// - [buffer]: 接收解码结果的缓冲区
///
/// ## 返回值
///
/// - `null`: 解码完成，没有剩余数字
/// - [_lastPercent]: 以 `%` 结尾
/// - 其他值: 以 `%X` 结尾，返回 X 的值（16 的倍数）
int? _decode(List<int> codeUnits, int start, int end, Uint8Buffer buffer) {
  // 对所有码点进行位运算 OR
  // 这样可以在不增加主循环分支的情况下检测越界码点
  var codeUnitOr = 0;

  // 当前连续非 % 字符切片的起始位置
  // 我们可以一次性将这些字符添加到缓冲区
  var sliceStart = start;

  for (var i = start; i < end; i++) {
    // 首先，循环处理非 % 字符
    var codeUnit = codeUnits[i];
    if (codeUnits[i] != $percent) {
      codeUnitOr |= codeUnit;
      continue;
    }

    // 找到了 %。从 sliceStart 到 i 的切片表示可以直接复制到缓冲区的字符
    if (i > sliceStart) {
      _checkForInvalidCodeUnit(codeUnitOr, codeUnits, sliceStart, i);
      buffer.addAll(codeUnits, sliceStart, i);
    }

    // 现在解码百分号编码的字节并添加它
    i++;
    if (i >= end) return _lastPercent;

    final firstDigit = digitForCodeUnit(codeUnits, i);
    i++;
    if (i >= end) return 16 * firstDigit;

    final secondDigit = digitForCodeUnit(codeUnits, i);
    buffer.add(16 * firstDigit + secondDigit);

    // 下一次迭代将再次查找非 % 字符
    sliceStart = i + 1;
  }

  // 处理剩余的非 % 字符
  if (end > sliceStart) {
    _checkForInvalidCodeUnit(codeUnitOr, codeUnits, sliceStart, end);
    if (start == sliceStart) {
      buffer.addAll(codeUnits);
    } else {
      buffer.addAll(codeUnits, sliceStart, end);
    }
  }

  return null;
}

/// 检查是否有无效的码点（非 ASCII）。
///
/// 使用位运算 OR 的结果快速检查是否所有码点都在 ASCII 范围内。
/// 如果发现非 ASCII 码点，抛出 [FormatException]。
///
/// ## 参数
///
/// - [codeUnitOr]: 所有码点的位运算 OR 结果
/// - [codeUnits]: 源码点数组
/// - [start]: 起始位置（包含）
/// - [end]: 结束位置（不包含）
void _checkForInvalidCodeUnit(
  int codeUnitOr,
  List<int> codeUnits,
  int start,
  int end,
) {
  if (codeUnitOr >= 0 && codeUnitOr <= 0x7f) return;

  for (var i = start; i < end; i++) {
    final codeUnit = codeUnits[i];
    if (codeUnit >= 0 && codeUnit <= 0x7f) continue;
    throw FormatException(
      '非 ASCII 码点 U+${codeUnit.toRadixString(16).padLeft(4, '0')}',
      codeUnits,
      i,
    );
  }
}
