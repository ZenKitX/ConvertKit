// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

/// 字符串累加器 Sink，提供对所有已传入字符串的访问。
///
/// [StringAccumulatorSink] 继承自 [StringConversionSinkBase]，
/// 专门用于收集和拼接字符串数据。与 [AccumulatorSink] 不同，
/// 它会自动将所有添加的字符串拼接成一个连续的字符串。
///
/// ## 特点
///
/// - 自动拼接多个字符串块
/// - 使用 [StringBuffer] 优化性能
/// - 支持切片添加（[addSlice]）
/// - 避免频繁的字符串拼接开销
///
/// ## 使用场景
///
/// - 收集分块字符串转换的结果
/// - 拼接多个字符串片段
/// - 流式文本数据处理
/// - 模板渲染和文本生成
///
/// ## 使用示例
///
/// ```dart
/// final sink = StringAccumulatorSink();
///
/// // 添加字符串块
/// sink.add('Hello');
/// sink.add(' ');
/// sink.add('World');
///
/// // 获取拼接后的字符串
/// final result = sink.string;
/// print(result); // "Hello World"
///
/// // 清空缓冲区
/// sink.clear();
/// print(sink.string); // ""
///
/// // 关闭 sink
/// sink.close();
/// ```
///
/// ## 与字符串转换器配合使用
///
/// ```dart
/// final sink = StringAccumulatorSink();
/// final encoder = hex.encoder;
/// final conversionSink = encoder.startChunkedConversion(sink);
///
/// conversionSink.add([72, 101, 108, 108, 111]); // "Hello" 的字节
/// conversionSink.close();
///
/// final hexString = sink.string;
/// print(hexString); // "48656c6c6f"
/// ```
///
/// ## 性能说明
///
/// 内部使用 [StringBuffer] 实现高效的字符串拼接，
/// 避免创建大量临时字符串对象。对于大量字符串拼接操作，
/// 性能远优于使用 `+` 运算符。
///
/// 参考: [StringConversionSink.withCallback]
class StringAccumulatorSink extends StringConversionSinkBase {
  /// 内部字符串缓冲区。
  final _buffer = StringBuffer();

  /// 是否已关闭的标志。
  var _isClosed = false;

  /// 获取所有已累积的字符串。
  ///
  /// 返回一个字符串，包含所有通过 [add] 或 [addSlice]
  /// 方法添加的字符串，按添加顺序拼接。
  ///
  /// 每次调用都会创建一个新的字符串对象。
  /// 如果需要频繁访问，建议缓存结果。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = StringAccumulatorSink();
  /// sink.add('Hello');
  /// sink.add(' ');
  /// sink.add('World');
  ///
  /// final result = sink.string;
  /// print(result); // "Hello World"
  /// ```
  String get string => _buffer.toString();

  /// 检查 sink 是否已关闭。
  ///
  /// 一旦调用 [close] 方法或 [addSlice] 的 `isLast` 参数为 `true`，
  /// 此属性将返回 `true`。关闭后的 sink 不能再添加新字符串。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = StringAccumulatorSink();
  /// print(sink.isClosed); // false
  ///
  /// sink.close();
  /// print(sink.isClosed); // true
  /// ```
  bool get isClosed => _isClosed;

  /// 清空所有已累积的字符串。
  ///
  /// 清空内部缓冲区，但不会关闭 sink。
  /// 清空后仍然可以继续添加新字符串。
  ///
  /// 这在需要重用 sink 或避免重复处理数据时很有用。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = StringAccumulatorSink();
  /// sink.add('Hello');
  /// sink.add('World');
  ///
  /// print(sink.string); // "HelloWorld"
  ///
  /// sink.clear();
  /// print(sink.string); // ""
  ///
  /// // 可以继续添加
  /// sink.add('New');
  /// print(sink.string); // "New"
  /// ```
  void clear() {
    _buffer.clear();
  }

  /// 添加一个字符串到 sink。
  ///
  /// 将 [str] 添加到内部缓冲区。
  /// 添加的字符串可以通过 [string] 属性访问。
  ///
  /// ## 参数
  ///
  /// - [str]: 要添加的字符串
  ///
  /// ## 异常
  ///
  /// 如果 sink 已经关闭（[isClosed] 为 `true`），
  /// 抛出 [StateError]。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = StringAccumulatorSink();
  /// sink.add('Hello');
  /// sink.add(' ');
  /// sink.add('World');
  ///
  /// print(sink.string); // "Hello World"
  /// ```
  @override
  void add(String str) {
    if (_isClosed) {
      throw StateError('无法向已关闭的 sink 添加数据');
    }

    _buffer.write(str);
  }

  /// 添加字符串的一个切片到 sink。
  ///
  /// 从 [chunk] 的 [start] 位置（包含）到 [end] 位置（不包含）
  /// 的子字符串添加到内部缓冲区。
  ///
  /// 如果 [isLast] 为 `true`，sink 将在添加后自动关闭。
  ///
  /// ## 参数
  ///
  /// - [chunk]: 源字符串
  /// - [start]: 起始位置（包含）
  /// - [end]: 结束位置（不包含）
  /// - [isLast]: 是否为最后一个切片
  ///
  /// ## 异常
  ///
  /// 如果 sink 已经关闭（[isClosed] 为 `true`），
  /// 抛出 [StateError]。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = StringAccumulatorSink();
  /// final text = 'Hello World';
  ///
  /// // 添加 "Hello"
  /// sink.addSlice(text, 0, 5, false);
  /// print(sink.string); // "Hello"
  ///
  /// // 添加 " World" 并关闭
  /// sink.addSlice(text, 5, 11, true);
  /// print(sink.string); // "Hello World"
  /// print(sink.isClosed); // true
  /// ```
  @override
  void addSlice(String chunk, int start, int end, bool isLast) {
    if (_isClosed) {
      throw StateError('无法向已关闭的 sink 添加数据');
    }

    _buffer.write(chunk.substring(start, end));
    if (isLast) {
      _isClosed = true;
    }
  }

  /// 关闭 sink。
  ///
  /// 标记 sink 为已关闭状态。关闭后不能再添加新字符串。
  /// 但仍然可以访问已累积的字符串和调用 [clear] 方法。
  ///
  /// 多次调用 [close] 是安全的，不会产生副作用。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = StringAccumulatorSink();
  /// sink.add('Hello');
  /// sink.close();
  ///
  /// // 仍然可以访问数据
  /// print(sink.string); // "Hello"
  ///
  /// // 但不能添加新数据
  /// sink.add('World'); // 抛出 StateError
  /// ```
  @override
  void close() {
    _isClosed = true;
  }
}
