// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

/// 内部身份转换器，直接返回输入。
class _IdentityConverter<T> extends Converter<T, T> {
  /// 创建一个身份转换器。
  _IdentityConverter();

  /// 直接返回输入，不做任何转换。
  @override
  T convert(T input) => input;
}

/// 身份编解码器，在两个方向上都不进行任何转换。
///
/// 身份编解码器在编码和解码时都直接传递输入到输出，不做任何修改。
/// 这个类可以用作组合多个编解码器时的基础，因为将身份编解码器
/// 与任何其他编解码器融合会返回另一个编解码器本身。
///
/// ## 使用场景
///
/// 1. 作为编解码器链的占位符
/// 2. 在需要 Codec 接口但不需要转换的场景
/// 3. 测试和调试编解码器管道
///
/// ## 使用示例
///
/// ```dart
/// // 创建身份编解码器
/// final identity = IdentityCodec<String>();
///
/// // 编码和解码都返回原始值
/// final encoded = identity.encode('Hello');
/// print(encoded); // "Hello"
///
/// final decoded = identity.decode('World');
/// print(decoded); // "World"
///
/// // 与其他编解码器融合
/// final utf8Codec = utf8;
/// final fused = identity.fuse(utf8Codec);
/// // fused 就是 utf8Codec 本身
/// ```
///
/// ## 融合行为
///
/// 当与其他编解码器融合时，身份编解码器会"消失"，
/// 返回另一个编解码器：
///
/// ```dart
/// final identity = IdentityCodec<List<int>>();
/// final hex = HexCodec();
///
/// // 融合后返回 hex 本身
/// final fused = identity.fuse(hex);
/// assert(identical(fused, hex));
/// ```
///
/// ## 性能说明
///
/// - 编码和解码都是 O(1) 操作
/// - 不分配额外内存
/// - 直接返回输入引用
class IdentityCodec<T> extends Codec<T, T> {
  /// 创建一个身份编解码器。
  ///
  /// 类型参数 [T] 指定输入和输出的类型。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// // 字符串身份编解码器
  /// final stringIdentity = IdentityCodec<String>();
  ///
  /// // 字节数组身份编解码器
  /// final bytesIdentity = IdentityCodec<List<int>>();
  ///
  /// // 任意类型身份编解码器
  /// final intIdentity = IdentityCodec<int>();
  /// ```
  const IdentityCodec();

  /// 获取身份解码器。
  ///
  /// 返回一个直接返回输入的转换器。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final identity = IdentityCodec<String>();
  /// final decoder = identity.decoder;
  /// print(decoder.convert('test')); // "test"
  /// ```
  @override
  Converter<T, T> get decoder => _IdentityConverter<T>();

  /// 获取身份编码器。
  ///
  /// 返回一个直接返回输入的转换器。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final identity = IdentityCodec<String>();
  /// final encoder = identity.encoder;
  /// print(encoder.convert('test')); // "test"
  /// ```
  @override
  Converter<T, T> get encoder => _IdentityConverter<T>();

  /// 与另一个编解码器融合。
  ///
  /// 与身份转换器融合是一个空操作，因此总是返回 [other]。
  /// 这是身份编解码器的关键特性：它在融合时"消失"。
  ///
  /// ## 参数
  ///
  /// - [other]: 要融合的另一个编解码器
  ///
  /// ## 返回值
  ///
  /// 直接返回 [other]，不做任何修改。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final identity = IdentityCodec<List<int>>();
  /// final hex = HexCodec();
  ///
  /// // 融合返回 hex 本身
  /// final fused = identity.fuse(hex);
  /// assert(identical(fused, hex));
  ///
  /// // 可以用于构建编解码器链
  /// final chain = identity
  ///     .fuse(utf8.encoder)
  ///     .fuse(hex);
  /// ```
  @override
  Codec<T, R> fuse<R>(Codec<T, R> other) => other;
}
