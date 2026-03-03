// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:convert_kit/src/string_accumulator_sink.dart';
import 'package:test/test.dart';

void main() {
  group('StringAccumulatorSink', () {
    late StringAccumulatorSink sink;

    setUp(() {
      sink = StringAccumulatorSink();
    });

    group('字符串拼接', () {
      test('应该提供对拼接字符串的访问', () {
        expect(sink.string, isEmpty);

        sink.add('foo');
        expect(sink.string, equals('foo'));

        sink.add('bar');
        expect(sink.string, equals('foobar'));
      });

      test('应该支持 addSlice 方法', () {
        sink.add('foo');
        sink.addSlice(' bar baz', 1, 4, false);

        expect(sink.string, equals('foobar'));
      });

      test('应该正确处理空字符串', () {
        sink.add('');
        expect(sink.string, isEmpty);

        sink.add('hello');
        expect(sink.string, equals('hello'));
      });

      test('应该支持多次添加', () {
        sink.add('a');
        sink.add('b');
        sink.add('c');
        sink.add('d');

        expect(sink.string, equals('abcd'));
      });

      test('应该支持包含特殊字符的字符串', () {
        sink.add('Hello\n');
        sink.add('World\t');
        sink.add('!');

        expect(sink.string, equals('Hello\nWorld\t!'));
      });

      test('应该支持 Unicode 字符', () {
        sink.add('你好');
        sink.add('世界');
        sink.add('🌍');

        expect(sink.string, equals('你好世界🌍'));
      });
    });

    group('清空操作', () {
      test('应该清空字符串', () {
        sink.add('foo');
        expect(sink.string, equals('foo'));

        sink.clear();
        expect(sink.string, isEmpty);
      });

      test('清空后应该可以继续添加字符串', () {
        sink.add('foo');
        sink.clear();

        sink.add('bar');
        expect(sink.string, equals('bar'));
      });

      test('清空空 sink 应该不会出错', () {
        expect(() => sink.clear(), returnsNormally);
        expect(sink.string, isEmpty);
      });

      test('应该支持多次清空', () {
        sink.add('a');
        sink.clear();
        sink.add('b');
        sink.clear();
        sink.add('c');

        expect(sink.string, equals('c'));
      });
    });

    group('关闭状态', () {
      test('应该正确指示 sink 是否已关闭', () {
        expect(sink.isClosed, isFalse);

        sink.close();
        expect(sink.isClosed, isTrue);
      });

      test('应该通过 addSlice 的 isLast 参数关闭', () {
        expect(sink.isClosed, isFalse);

        sink.addSlice('hello', 0, 5, true);
        expect(sink.isClosed, isTrue);
      });

      test('addSlice 的 isLast 为 false 不应该关闭', () {
        sink.addSlice('hello', 0, 5, false);
        expect(sink.isClosed, isFalse);
      });

      test('关闭后不应该允许 add', () {
        sink.close();
        expect(() => sink.add('x'), throwsStateError);
      });

      test('关闭后不应该允许 addSlice', () {
        sink.close();
        expect(() => sink.addSlice('', 0, 0, false), throwsStateError);
      });

      test('关闭后仍然可以访问字符串', () {
        sink.add('hello');
        sink.close();

        expect(sink.string, equals('hello'));
      });

      test('关闭后仍然可以清空字符串', () {
        sink.add('hello');
        sink.close();

        expect(() => sink.clear(), returnsNormally);
        expect(sink.string, isEmpty);
      });

      test('多次关闭应该是安全的', () {
        sink.close();
        expect(() => sink.close(), returnsNormally);
        expect(sink.isClosed, isTrue);
      });
    });

    group('边界情况', () {
      test('应该处理长字符串', () {
        final longString = 'a' * 10000;
        sink.add(longString);

        expect(sink.string.length, equals(10000));
        expect(sink.string, equals(longString));
      });

      test('应该正确处理 addSlice 的边界', () {
        const text = 'Hello World';

        // 添加整个字符串
        sink.addSlice(text, 0, 11, false);
        expect(sink.string, equals('Hello World'));

        sink.clear();

        // 添加空切片
        sink.addSlice(text, 5, 5, false);
        expect(sink.string, isEmpty);

        // 添加单个字符
        sink.addSlice(text, 0, 1, false);
        expect(sink.string, equals('H'));
      });

      test('应该保持字符串顺序', () {
        final parts = ['Hello', ' ', 'World', '!'];

        for (final part in parts) {
          sink.add(part);
        }

        expect(sink.string, equals('Hello World!'));
      });

      test('应该处理连续的空字符串', () {
        sink.add('');
        sink.add('');
        sink.add('hello');
        sink.add('');
        sink.add('world');
        sink.add('');

        expect(sink.string, equals('helloworld'));
      });

      test('应该正确处理 addSlice 的各种范围', () {
        const text = '0123456789';

        // 前半部分
        sink.addSlice(text, 0, 5, false);
        expect(sink.string, equals('01234'));

        sink.clear();

        // 后半部分
        sink.addSlice(text, 5, 10, false);
        expect(sink.string, equals('56789'));

        sink.clear();

        // 中间部分
        sink.addSlice(text, 3, 7, false);
        expect(sink.string, equals('3456'));
      });

      test('应该处理多行文本', () {
        sink.add('Line 1\n');
        sink.add('Line 2\n');
        sink.add('Line 3');

        expect(sink.string, equals('Line 1\nLine 2\nLine 3'));
      });
    });
  });
}
