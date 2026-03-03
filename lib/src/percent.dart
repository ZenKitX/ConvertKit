// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'percent/decoder.dart';
import 'percent/encoder.dart';

export 'percent/decoder.dart' hide percentDecoder;
export 'percent/encoder.dart' hide percentEncoder;

/// [PercentCodec] 的规范实例。
const percent = PercentCodec._();

/// 百分号编解码器，用于在字节数组和百分号编码（URL 编码）字符串之间转换。
///
/// 遵循 [RFC 3986](https://tools.ietf.org/html/rfc3986#section-2.1) 规范。
///
/// ## 编码规则
///
/// [encoder] 编码所有字节，除了：
/// - ASCII 字母：A-Z, a-z
/// - 数字：0-9
/// - 特殊字符：`-`, `.`, `_`, `~`
///
/// 这与 [Uri.encodeQueryComponent] 的行为匹配，但不将 `0x20`（空格）编码为 `+`。
///
/// ## 解码规则
///
/// [decoder] 最大限度地灵活：
/// - 解码任何百分号编码的字节
/// - 允许任何非百分号编码的字节（除了 `%`）
/// - 默认将 `+` 解释为 `0x2B`（而非 `0x20`）
///
/// ## 使用示例
///
/// ```dart
/// // 编码
/// final encoded = percent.encode([65, 66, 67, 32, 49, 50, 51]);
/// print(encoded); // "ABC%20123"
///
/// // 解码
/// final decoded = percent.decode('ABC%20123');
/// print(decoded); // [65, 66, 67, 32, 49, 50, 51]
///
/// // 往返转换
/// final original = [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100];
/// final roundTrip = percent.decode(percent.encode(original));
/// print(roundTrip); // [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100]
/// ```
///
/// ## 与 Uri 编解码的区别
///
/// - 本编解码器不将空格编码为 `+`
/// - 空格编码为 `%20`
/// - 解码时 `+` 保持为 `0x2B`
///
/// ## 流式处理
///
/// ```dart
/// // 编码流
/// final encodeStream = Stream.fromIterable([
///   [65, 66, 67],
///   [32, 49, 50, 51],
/// ]).transform(percent.encoder);
///
/// // 解码流
/// final decodeStream = Stream.fromIterable([
///   'ABC%',
///   '20123',
/// ]).transform(percent.decoder);
/// ```
///
/// ## 性能说明
///
/// - 编码和解码都是 O(n) 时间复杂度
/// - 使用高效的缓冲区构建结果
/// - 支持分块处理大数据
class PercentCodec extends Codec<List<int>, String> {
  /// 获取百分号编码器。
  ///
  /// 返回用于将字节数组编码为百分号编码字符串的编码器。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final encoder = percent.encoder;
  /// final encoded = encoder.convert([65, 66, 67]);
  /// print(encoded); // "ABC"
  /// ```
  @override
  PercentEncoder get encoder => percentEncoder;

  /// 获取百分号解码器。
  ///
  /// 返回用于将百分号编码字符串解码为字节数组的解码器。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final decoder = percent.decoder;
  /// final decoded = decoder.convert('ABC%20123');
  /// print(decoded); // [65, 66, 67, 32, 49, 50, 51]
  /// ```
  @override
  PercentDecoder get decoder => percentDecoder;

  /// 创建一个百分号编解码器。
  const PercentCodec._();
}
