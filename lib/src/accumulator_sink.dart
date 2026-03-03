// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';

/// 累加器 Sink，提供对所有已传入事件的访问。
///
/// [AccumulatorSink] 实现了 [Sink] 接口，用于收集和存储传入的事件。
/// 与普通的 Sink 不同，它允许在任何时候访问已收集的所有事件。
///
/// 这在需要同步访问分块转换器输出时特别有用。
///
/// ## 使用场景
///
/// - 收集分块转换的中间结果
/// - 测试和调试转换器
/// - 需要多次访问转换结果的场景
///
/// ## 使用示例
///
/// ```dart
/// final sink = AccumulatorSink<String>();
///
/// // 添加事件
/// sink.add('Hello');
/// sink.add('World');
///
/// // 访问所有事件
/// print(sink.events); // ['Hello', 'World']
///
/// // 清空事件
/// sink.clear();
/// print(sink.events); // []
///
/// // 关闭 sink
/// sink.close();
/// ```
///
/// ## 与分块转换器配合使用
///
/// ```dart
/// final sink = AccumulatorSink<String>();
/// final converter = MyConverter();
/// final conversionSink = converter.startChunkedConversion(sink);
///
/// conversionSink.add('chunk1');
/// conversionSink.add('chunk2');
/// conversionSink.close();
///
/// // 获取所有转换结果
/// final results = sink.events;
/// ```
///
/// 参考: [ChunkedConversionSink.withCallback]
class AccumulatorSink<T> implements Sink<T> {
  /// 内部事件列表。
  final _events = <T>[];

  /// 是否已关闭的标志。
  var _isClosed = false;

  /// 获取所有已传入的事件。
  ///
  /// 返回一个不可修改的列表视图，包含所有通过 [add] 方法添加的事件。
  /// 列表按照事件添加的顺序排列。
  ///
  /// 返回的列表是只读的，尝试修改会抛出 [UnsupportedError]。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = AccumulatorSink<int>();
  /// sink.add(1);
  /// sink.add(2);
  /// sink.add(3);
  ///
  /// print(sink.events); // [1, 2, 3]
  /// ```
  List<T> get events => UnmodifiableListView(_events);

  /// 检查 sink 是否已关闭。
  ///
  /// 一旦调用 [close] 方法，此属性将返回 `true`。
  /// 关闭后的 sink 不能再添加新事件。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = AccumulatorSink<String>();
  /// print(sink.isClosed); // false
  ///
  /// sink.close();
  /// print(sink.isClosed); // true
  /// ```
  bool get isClosed => _isClosed;

  /// 清空所有已收集的事件。
  ///
  /// 移除 [events] 列表中的所有元素，但不会关闭 sink。
  /// 清空后仍然可以继续添加新事件。
  ///
  /// 这在需要重用 sink 或避免重复处理事件时很有用。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = AccumulatorSink<String>();
  /// sink.add('event1');
  /// sink.add('event2');
  ///
  /// print(sink.events.length); // 2
  ///
  /// sink.clear();
  /// print(sink.events.length); // 0
  ///
  /// // 可以继续添加
  /// sink.add('event3');
  /// print(sink.events); // ['event3']
  /// ```
  void clear() {
    _events.clear();
  }

  /// 添加一个事件到 sink。
  ///
  /// 将 [event] 添加到内部事件列表中。
  /// 添加的事件可以通过 [events] 属性访问。
  ///
  /// ## 参数
  ///
  /// - [event]: 要添加的事件
  ///
  /// ## 异常
  ///
  /// 如果 sink 已经关闭（[isClosed] 为 `true`），
  /// 抛出 [StateError]。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = AccumulatorSink<int>();
  /// sink.add(42);
  /// sink.add(100);
  ///
  /// print(sink.events); // [42, 100]
  /// ```
  @override
  void add(T event) {
    if (_isClosed) {
      throw StateError('无法向已关闭的 sink 添加事件');
    }

    _events.add(event);
  }

  /// 关闭 sink。
  ///
  /// 标记 sink 为已关闭状态。关闭后不能再添加新事件。
  /// 但仍然可以访问已收集的事件和调用 [clear] 方法。
  ///
  /// 多次调用 [close] 是安全的，不会产生副作用。
  ///
  /// ## 示例
  ///
  /// ```dart
  /// final sink = AccumulatorSink<String>();
  /// sink.add('data');
  /// sink.close();
  ///
  /// // 仍然可以访问数据
  /// print(sink.events); // ['data']
  ///
  /// // 但不能添加新数据
  /// sink.add('more'); // 抛出 StateError
  /// ```
  @override
  void close() {
    _isClosed = true;
  }
}
