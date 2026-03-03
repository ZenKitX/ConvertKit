// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'hex/decoder.dart';
import 'hex/encoder.dart';

export 'hex/decoder.dart' hide hexDecoder;
export 'hex/encoder.dart' hide hexEncoder;

/// [HexCodec] 的规范实例。
///
/// 这是推荐使用的方式，通过这个常量实例访问十六进制编解码功能。
///
/// ## 使用示例
///
/// ```dart
/// import 'package:convert_kit/convert_kit.dart';
///
/// // 编码
/// final encoded = hex.encode([255, 254, 253]);
/// print(encoded); // "fffefd"
///
/// // 解码
/// final decoded = hex.decode('fffefd');
/// print(decoded); // [255, 254, 253]
/// ```
const hex = HexCodec._();

/// 十六进制编解码器。
///
/// 将字节数组与十六进制字符串相互转换，遵循
/// [RFC 4648 Base16 规范](https://tools.ietf.org/html/rfc4648#section-8)。
///
/// ## 功能特性
///
/// - 编码：将字节数组转换为十六进制字符串（小写）
/// - 解码：将十六进制字符串转换为字节数组（支持大小写混合）
/// - 支持分块转换，适用于流式数据处理
/// - 高性能实现，使用位运算优化
///
/// ## 使用方式
///
/// 推荐通过 [hex] 常量使用，而不是直接实例化此类。
///
/// ## 编码示例
///
/// ```dart
/// // 编码字节数组
/// final bytes = [72, 101, 108, 108, 111]; // "Hello"
/// final hexString = hex.encode(bytes);
/// print(hexString); // "48656c6c6f"
///
/// // 编码 UTF-8 字符串
/// final utf8Bytes = utf8.encode('你好');
/// final hexUtf8 = hex.encode(utf8Bytes);
/// print(hexUtf8); // UTF-8 编码的十六进制表示
/// ```
///
/// ## 解码示例
///
/// ```dart
/// // 解码十六进制字符串
/// final decoded = hex.decode('48656c6c6f');
/// print(String.fromCharCodes(decoded)); // "Hello"
///
/// // 支持大小写混合
/// final mixed = hex.decode('FfFeFd');
/// print(mixed); // [255, 254, 253]
/// ```
///
/// ## 与其他编解码器组合
///
/// ```dart
/// // 与 UTF-8 组合
/// final utf8Hex = utf8.fuse(hex);
/// final encoded = utf8Hex.encode('Hello');
/// print(encoded); // "48656c6c6f"
///
/// final decoded = utf8Hex.decode('48656c6c6f');
/// print(decoded); // "Hello"
/// ```
///
/// ## 分块转换
///
/// ```dart
/// // 编码分块
/// final encodeSink = StringBuffer();
/// final encodeConversion = hex.encoder.startChunkedConversion(
///   StringConversionSink.fromStringSink(encodeSink),
/// );
/// encodeConversion.add([1, 2, 3]);
/// encodeConversion.add([4, 5, 6]);
/// encodeConversion.close();
/// print(encodeSink); // "010203040506"
///
/// // 解码分块
/// final decodeSink = ByteAccumulatorSink();
/// final decodeConversion = hex.decoder.startChunkedConversion(decodeSink);
/// decodeConversion.add('0102');
/// decodeConversion.add('0304');
/// decodeConversion.close();
/// print(decodeSink.bytes); // [1, 2, 3, 4]
/// ```
///
/// ## 性能说明
///
/// - 编码：O(n) 时间，O(2n) 空间
/// - 解码：O(n) 时间，O(n/2) 空间
/// - 使用类型化数组和位运算优化性能
/// - 适合处理大量数据
///
/// ## 错误处理
///
/// 编码时：
/// - 如果输入包含不在 0-255 范围内的值，抛出 [FormatException]
///
/// 解码时：
/// - 如果输入长度为奇数，抛出 [FormatException]
/// - 如果包含非十六进制字符，抛出 [FormatException]
///
/// ## 参考
///
/// - [RFC 4648 Section 8](https://tools.ietf.org/html/rfc4648#section-8)
/// - [HexEncoder] - 编码器实现
/// - [HexDecoder] - 解码器实现
class HexCodec extends Codec<List<int>, String> {
  /// 创建一个十六进制编解码器。
  ///
  /// 通常不需要直接调用此构造函数，使用 [hex] 常量即可。
  const HexCodec._();

  /// 获取十六进制编码器。
  ///
  /// 返回 [HexEncoder] 实例，用于将字节数组编码为十六进制字符串。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final encoder = hex.encoder;
  /// final encoded = encoder.convert([255, 254, 253]);
  /// print(encoded); // "fffefd"
  /// ```
  @override
  HexEncoder get encoder => hexEncoder;

  /// 获取十六进制解码器。
  ///
  /// 返回 [HexDecoder] 实例，用于将十六进制字符串解码为字节数组。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final decoder = hex.decoder;
  /// final decoded = decoder.convert('fffefd');
  /// print(decoded); // [255, 254, 253]
  /// ```
  @override
  HexDecoder get decoder => hexDecoder;
}
