// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:convert_kit/src/byte_accumulator_sink.dart';
import 'package:test/test.dart';

void main() {
  group('ByteAccumulatorSink', () {
    late ByteAccumulatorSink sink;

    setUp(() {
      sink = ByteAccumulatorSink();
    });

    group('字节拼接', () {
      test('应该提供对拼接字节的访问', () {
        expect(sink.bytes, isEmpty);

        sink.add([1, 2, 3]);
        expect(sink.bytes, equals([1, 2, 3]));

        sink.add([4, 5, 6]);
        expect(sink.bytes, equals([1, 2, 3, 4, 5, 6]));
      });

      test('应该支持 addSlice 方法', () {
        sink.add([1, 2, 3]);
        sink.addSlice([4, 5, 6, 7, 8], 1, 4, false);

        expect(sink.bytes, equals([1, 2, 3, 5, 6, 7]));
      });

      test('应该返回 Uint8List 类型', () {
        sink.add([1, 2, 3]);
        expect(sink.bytes, isA<Uint8List>());
      });

      test('应该正确处理空字节列表', () {
        sink.add([]);
        expect(sink.bytes, isEmpty);

        sink.add([1, 2, 3]);
        expect(sink.bytes, equals([1, 2, 3]));
      });
    });

    group('清空操作', () {
      test('应该清空所有字节', () {
        sink.add([1, 2, 3]);
        expect(sink.bytes, equals([1, 2, 3]));

        sink.clear();
        expect(sink.bytes, isEmpty);
      });

      test('清空后应该可以继续添加字节', () {
        sink.add([1, 2, 3]);
        sink.clear();

        sink.add([4, 5, 6]);
        expect(sink.bytes, equals([4, 5, 6]));
      });

      test('清空空 sink 应该不会出错', () {
        expect(() => sink.clear(), returnsNormally);
        expect(sink.bytes, isEmpty);
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

        sink.addSlice([1, 2, 3], 0, 3, true);
        expect(sink.isClosed, isTrue);
      });

      test('addSlice 的 isLast 为 false 不应该关闭', () {
        sink.addSlice([1, 2, 3], 0, 3, false);
        expect(sink.isClosed, isFalse);
      });

      test('关闭后不应该允许 add', () {
        sink.close();
        expect(() => sink.add([1]), throwsStateError);
      });

      test('关闭后不应该允许 addSlice', () {
        sink.close();
        expect(() => sink.addSlice([], 0, 0, false), throwsStateError);
      });

      test('关闭后仍然可以访问字节', () {
        sink.add([1, 2, 3]);
        sink.close();

        expect(sink.bytes, equals([1, 2, 3]));
      });

      test('关闭后仍然可以清空字节', () {
        sink.add([1, 2, 3]);
        sink.close();

        expect(() => sink.clear(), returnsNormally);
        expect(sink.bytes, isEmpty);
      });

      test('多次关闭应该是安全的', () {
        sink.close();
        expect(() => sink.close(), returnsNormally);
        expect(sink.isClosed, isTrue);
      });
    });

    group('边界情况', () {
      test('应该处理大量字节', () {
        for (var i = 0; i < 100; i++) {
          sink.add([i % 256]);
        }

        expect(sink.bytes.length, equals(100));
        expect(sink.bytes.first, equals(0));
        expect(sink.bytes.last, equals(99));
      });

      test('应该正确处理 addSlice 的边界', () {
        final data = [1, 2, 3, 4, 5];

        // 添加整个列表
        sink.addSlice(data, 0, 5, false);
        expect(sink.bytes, equals([1, 2, 3, 4, 5]));

        sink.clear();

        // 添加空切片
        sink.addSlice(data, 2, 2, false);
        expect(sink.bytes, isEmpty);

        // 添加单个元素
        sink.addSlice(data, 2, 3, false);
        expect(sink.bytes, equals([3]));
      });

      test('应该保持字节顺序', () {
        final bytes1 = [1, 2, 3];
        final bytes2 = [4, 5, 6];
        final bytes3 = [7, 8, 9];

        sink.add(bytes1);
        sink.add(bytes2);
        sink.add(bytes3);

        expect(sink.bytes, equals([1, 2, 3, 4, 5, 6, 7, 8, 9]));
      });

      test('应该处理 0-255 范围内的所有字节值', () {
        final allBytes = List.generate(256, (i) => i);
        sink.add(allBytes);

        expect(sink.bytes.length, equals(256));
        for (var i = 0; i < 256; i++) {
          expect(sink.bytes[i], equals(i));
        }
      });
    });
  });
}
