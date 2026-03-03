// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:typed_data/typed_data.dart';

/// 字节累加器 Sink，提供对所有已传入字节的访问。
///
/// [ByteAccumulatorSink] 继承自 [ByteConversionSinkBase]，
/// 专门用于收集和拼接字节数据。与 [AccumulatorSink] 不同，
/// 它会自动将所有添加的字节列表拼接成一个连续的 [Uint8List]。
///
/// ## 特点
///
/// - 自动拼接多个字节块
/// - 返回高效的 [Uint8List] 视图
/// - 支持切片添加（[addSlice]）
/// - 内存高效的缓冲区管理
///
/// ## 使用场景
///
/// - 收集分块字节转换的结果
/// - 拼接多个字节数组
/// - 流式字节数据处理
/// - 网络数据接收
///
/// ## 使用示例
///
/// ```dart
/// final sink = ByteAccumulatorSink();
///
/// // 添加字节块
/// sink.add([1, 2, 3]);
/// sink.add([4, 5, 6]);
///
/// // 获取拼接后的字节
/// final bytes = sink.bytes;
/// print(bytes); // [1, 2, 3, 4, 5, 6]
///
/// // 清空缓冲区
/// sink.clear();
/// print(sink.bytes); // []
///
/// // 关闭 sink
/// sink.close();
/// ```
///
/// ## 与字节转换器配合使用
///
/// ```dart
/// final sink = ByteAccumulatorSink();
/// final decoder = hex.decoder;
/// final conversionSink = decoder.startChunkedConversion(sink);
///
/// conversionSink.add('48656c6c6f'); // "Hello" 的十六进制
/// conversionSink.close();
///
/// final bytes = sink.bytes;
/// print(String.fromCharCodes(bytes)); // "Hello"
/// ```
///
/// ## 性能说明
///
/// 内部使用 [Uint8Buffer] 实现高效的动态缓冲区，
/// 避免频繁的内存分配和拷贝。
///
/// 参考: [ByteConversionSink.withCallback]
class ByteAccumulatorSink extends ByteConversionSinkBase {
  /// 内部字节缓冲区。
  final _buffer = Uint8Buffer();

  /// 是否已关闭的标志。
  var _isClosed = false;

  /// 获取所有已累积的字节。
  ///
  /// 返回一个 [Uint8List]，包含所有通过 [add] 或 [addSlice]
  /// 方法添加的字节，按添加顺序拼接。
  ///
  /// 返回的 [Uint8List] 是共享缓冲区的视图，因此：
  /// - 不应该修改返回的列表
  /// - 不应该访问视图范围外的字节
  /// - 在添加新数据后，之前获取的视图可能失效
  ///
  /// 如果需要独立的副本，使用 `Uint8List.fromList(sink.bytes)`。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = ByteAccumulatorSink();
  /// sink.add([72, 101, 108, 108, 111]); // "Hello"
  ///
  /// final bytes = sink.bytes;
  /// print(String.fromCharCodes(bytes)); // "Hello"
  /// ```
  Uint8List get bytes => Uint8List.view(_buffer.buffer, 0, _buffer.length);

  /// 检查 sink 是否已关闭。
  ///
  /// 一旦调用 [close] 方法或 [addSlice] 的 `isLast` 参数为 `true`，
  /// 此属性将返回 `true`。关闭后的 sink 不能再添加新字节。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = ByteAccumulatorSink();
  /// print(sink.isClosed); // false
  ///
  /// sink.close();
  /// print(sink.isClosed); // true
  /// ```
  bool get isClosed => _isClosed;

  /// 清空所有已累积的字节。
  ///
  /// 移除缓冲区中的所有字节，但不会关闭 sink。
  /// 清空后仍然可以继续添加新字节。
  ///
  /// 这在需要重用 sink 或避免重复处理数据时很有用。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = ByteAccumulatorSink();
  /// sink.add([1, 2, 3]);
  ///
  /// print(sink.bytes.length); // 3
  ///
  /// sink.clear();
  /// print(sink.bytes.length); // 0
  ///
  /// // 可以继续添加
  /// sink.add([4, 5, 6]);
  /// print(sink.bytes); // [4, 5, 6]
  /// ```
  void clear() {
    _buffer.clear();
  }

  /// 添加一个字节块到 sink。
  ///
  /// 将 [chunk] 中的所有字节添加到内部缓冲区。
  /// 添加的字节可以通过 [bytes] 属性访问。
  ///
  /// ## 参数
  ///
  /// - [chunk]: 要添加的字节列表
  ///
  /// ## 异常
  ///
  /// 如果 sink 已经关闭（[isClosed] 为 `true`），
  /// 抛出 [StateError]。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = ByteAccumulatorSink();
  /// sink.add([1, 2, 3]);
  /// sink.add([4, 5, 6]);
  ///
  /// print(sink.bytes); // [1, 2, 3, 4, 5, 6]
  /// ```
  @override
  void add(List<int> chunk) {
    if (_isClosed) {
      throw StateError('无法向已关闭的 sink 添加数据');
    }

    _buffer.addAll(chunk);
  }

  /// 添加字节列表的一个切片到 sink。
  ///
  /// 从 [chunk] 的 [start] 位置（包含）到 [end] 位置（不包含）
  /// 的字节添加到内部缓冲区。
  ///
  /// 如果 [isLast] 为 `true`，sink 将在添加后自动关闭。
  ///
  /// ## 参数
  ///
  /// - [chunk]: 源字节列表
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
  /// final sink = ByteAccumulatorSink();
  /// final data = [1, 2, 3, 4, 5, 6];
  ///
  /// // 添加前 3 个字节
  /// sink.addSlice(data, 0, 3, false);
  /// print(sink.bytes); // [1, 2, 3]
  ///
  /// // 添加后 3 个字节并关闭
  /// sink.addSlice(data, 3, 6, true);
  /// print(sink.bytes); // [1, 2, 3, 4, 5, 6]
  /// print(sink.isClosed); // true
  /// ```
  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    if (_isClosed) {
      throw StateError('无法向已关闭的 sink 添加数据');
    }

    _buffer.addAll(chunk, start, end);
    if (isLast) {
      _isClosed = true;
    }
  }

  /// 关闭 sink。
  ///
  /// 标记 sink 为已关闭状态。关闭后不能再添加新字节。
  /// 但仍然可以访问已累积的字节和调用 [clear] 方法。
  ///
  /// 多次调用 [close] 是安全的，不会产生副作用。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = ByteAccumulatorSink();
  /// sink.add([1, 2, 3]);
  /// sink.close();
  ///
  /// // 仍然可以访问数据
  /// print(sink.bytes); // [1, 2, 3]
  ///
  /// // 但不能添加新数据
  /// sink.add([4, 5, 6]); // 抛出 StateError
  /// ```
  @override
  void close() {
    _isClosed = true;
  }
}
