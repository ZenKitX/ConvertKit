// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:convert_kit/src/accumulator_sink.dart';
import 'package:test/test.dart';

void main() {
  group('AccumulatorSink', () {
    late AccumulatorSink<int> sink;

    setUp(() {
      sink = AccumulatorSink<int>();
    });

    group('事件收集', () {
      test('应该在添加事件时提供访问', () {
        expect(sink.events, isEmpty);

        sink.add(1);
        expect(sink.events, equals([1]));

        sink.add(2);
        expect(sink.events, equals([1, 2]));

        sink.add(3);
        expect(sink.events, equals([1, 2, 3]));
      });

      test('应该返回不可修改的列表', () {
        sink.add(1);
        final events = sink.events;

        expect(() => events.add(2), throwsUnsupportedError);
      });

      test('应该支持不同类型的事件', () {
        final stringSink = AccumulatorSink<String>();
        stringSink.add('hello');
        stringSink.add('world');

        expect(stringSink.events, equals(['hello', 'world']));
        stringSink.close();
      });
    });

    group('清空操作', () {
      test('应该清空所有事件', () {
        sink
          ..add(1)
          ..add(2)
          ..add(3);
        expect(sink.events, equals([1, 2, 3]));

        sink.clear();
        expect(sink.events, isEmpty);
      });

      test('清空后应该可以继续添加事件', () {
        sink
          ..add(1)
          ..add(2)
          ..add(3);
        sink.clear();

        sink
          ..add(4)
          ..add(5)
          ..add(6);
        expect(sink.events, equals([4, 5, 6]));
      });

      test('清空空 sink 应该不会出错', () {
        expect(() => sink.clear(), returnsNormally);
        expect(sink.events, isEmpty);
      });
    });

    group('关闭状态', () {
      test('应该正确指示 sink 是否已关闭', () {
        expect(sink.isClosed, isFalse);

        sink.close();
        expect(sink.isClosed, isTrue);
      });

      test('关闭后不应该允许添加事件', () {
        sink.close();
        expect(() => sink.add(1), throwsStateError);
      });

      test('关闭后仍然可以访问事件', () {
        sink.add(1);
        sink.add(2);
        sink.close();

        expect(sink.events, equals([1, 2]));
      });

      test('关闭后仍然可以清空事件', () {
        sink.add(1);
        sink.close();

        expect(() => sink.clear(), returnsNormally);
        expect(sink.events, isEmpty);
      });

      test('多次关闭应该是安全的', () {
        sink.close();
        expect(() => sink.close(), returnsNormally);
        expect(sink.isClosed, isTrue);
      });
    });

    group('边界情况', () {
      test('应该处理空事件列表', () {
        expect(sink.events, isEmpty);
        expect(sink.events.length, equals(0));
      });

      test('应该处理大量事件', () {
        for (var i = 0; i < 1000; i++) {
          sink.add(i);
        }

        expect(sink.events.length, equals(1000));
        expect(sink.events.first, equals(0));
        expect(sink.events.last, equals(999));
      });

      test('应该保持事件顺序', () {
        final numbers = [5, 2, 8, 1, 9, 3];
        for (final num in numbers) {
          sink.add(num);
        }

        expect(sink.events, equals(numbers));
      });
    });
  });
}
