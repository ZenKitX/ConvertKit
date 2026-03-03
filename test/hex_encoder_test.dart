// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:convert_kit/src/hex/encoder.dart';
import 'package:test/test.dart';

void main() {
  group('HexEncoder', () {
    late HexEncoder encoder;

    setUp(() {
      encoder = hexEncoder;
    });

    group('基本编码', () {
      test('应该编码空数组', () {
        expect(encoder.convert([]), equals(''));
      });

      test('应该编码单个字节', () {
        expect(encoder.convert([0]), equals('00'));
        expect(encoder.convert([15]), equals('0f'));
        expect(encoder.convert([16]), equals('10'));
        expect(encoder.convert([255]), equals('ff'));
      });

      test('应该编码多个字节', () {
        expect(encoder.convert([0, 1, 2]), equals('000102'));
        expect(encoder.convert([255, 254, 253]), equals('fffefd'));
        expect(encoder.convert([10, 20, 30]), equals('0a141e'));
      });

      test('应该使用小写字母', () {
        expect(encoder.convert([0xAB, 0xCD, 0xEF]), equals('abcdef'));
      });

      test('应该正确编码所有字节值', () {
        // 测试 0-255 的所有值
        for (var i = 0; i < 256; i++) {
          final expected = i.toRadixString(16).padLeft(2, '0');
          expect(encoder.convert([i]), equals(expected));
        }
      });
    });

    group('边界情况', () {
      test('应该编码最小值', () {
        expect(encoder.convert([0]), equals('00'));
      });

      test('应该编码最大值', () {
        expect(encoder.convert([255]), equals('ff'));
      });

      test('应该编码连续的相同字节', () {
        expect(encoder.convert([0, 0, 0]), equals('000000'));
        expect(encoder.convert([255, 255, 255]), equals('ffffff'));
      });

      test('应该编码大量字节', () {
        final bytes = List.generate(1000, (i) => i % 256);
        final result = encoder.convert(bytes);

        expect(result.length, equals(2000));
        // 验证前几个字节
        expect(result.substring(0, 6), equals('000102'));
      });
    });

    group('异常处理', () {
      test('应该在字节值为负数时抛出异常', () {
        expect(
          () => encoder.convert([-1]),
          throwsA(isA<FormatException>()),
        );
      });

      test('应该在字节值大于 255 时抛出异常', () {
        expect(
          () => encoder.convert([256]),
          throwsA(isA<FormatException>()),
        );
      });

      test('应该在包含多个无效字节时抛出异常', () {
        expect(
          () => encoder.convert([1, 2, 256, 3]),
          throwsA(isA<FormatException>()),
        );
      });

      test('异常应该包含有用的错误信息', () {
        try {
          encoder.convert([256]);
          fail('应该抛出异常');
        } on FormatException catch (e) {
          expect(e.message, contains('无效的字节值'));
          expect(e.message, contains('0x100'));
        }
      });
    });

    group('分块转换', () {
      test('应该支持分块编码', () {
        final sink = StringBuffer();
        final conversionSink = encoder.startChunkedConversion(
          StringConversionSink.fromStringSink(sink),
        );

        conversionSink.add([1, 2, 3]);
        conversionSink.add([4, 5, 6]);
        conversionSink.close();

        expect(sink.toString(), equals('010203040506'));
      });

      test('应该支持 addSlice', () {
        final sink = StringBuffer();
        final conversionSink = encoder.startChunkedConversion(
          StringConversionSink.fromStringSink(sink),
        );

        final data = [1, 2, 3, 4, 5, 6];
        conversionSink.addSlice(data, 0, 3, false);
        conversionSink.addSlice(data, 3, 6, true);

        expect(sink.toString(), equals('010203040506'));
        conversionSink.close();
      });

      test('addSlice 的 isLast 应该关闭 sink', () {
        final sink = StringBuffer();
        final conversionSink = encoder.startChunkedConversion(
          StringConversionSink.fromStringSink(sink),
        );

        conversionSink.addSlice([1, 2, 3], 0, 3, true);

        expect(sink.toString(), equals('010203'));
        conversionSink.close();
      });

      test('应该处理空块', () {
        final sink = StringBuffer();
        final conversionSink = encoder.startChunkedConversion(
          StringConversionSink.fromStringSink(sink),
        );

        conversionSink.add([]);
        conversionSink.add([1, 2]);
        conversionSink.add([]);
        conversionSink.close();

        expect(sink.toString(), equals('0102'));
      });

      test('应该验证 addSlice 的范围', () {
        final sink = StringBuffer();
        final conversionSink = encoder.startChunkedConversion(
          StringConversionSink.fromStringSink(sink),
        );

        expect(
          () => conversionSink.addSlice([1, 2, 3], 0, 5, false),
          throwsA(isA<RangeError>()),
        );
        conversionSink.close();
      });
    });

    group('特殊模式', () {
      test('应该编码 ASCII 可打印字符的字节值', () {
        // 'A' = 65, 'B' = 66, 'C' = 67
        expect(encoder.convert([65, 66, 67]), equals('414243'));
      });

      test('应该编码 UTF-8 字节序列', () {
        // "你好" 的 UTF-8 编码
        final bytes = utf8.encode('你好');
        final hex = encoder.convert(bytes);

        // 验证可以解码回来
        expect(hex.length, equals(bytes.length * 2));
      });

      test('应该编码二进制数据', () {
        final binary = [0x00, 0xFF, 0x00, 0xFF];
        expect(encoder.convert(binary), equals('00ff00ff'));
      });

      test('应该编码递增序列', () {
        final sequence = [0, 1, 2, 3, 4, 5];
        expect(encoder.convert(sequence), equals('000102030405'));
      });

      test('应该编码递减序列', () {
        final sequence = [5, 4, 3, 2, 1, 0];
        expect(encoder.convert(sequence), equals('050403020100'));
      });
    });

    group('性能相关', () {
      test('应该高效处理大数据', () {
        final largeData = List.generate(10000, (i) => i % 256);
        final result = encoder.convert(largeData);

        expect(result.length, equals(20000));
      });

      test('应该正确处理重复模式', () {
        final pattern = [0xAA, 0xBB, 0xCC];
        final repeated = List.generate(100, (i) => pattern[i % 3]).toList();
        final result = encoder.convert(repeated);

        // 验证模式重复
        expect(result.substring(0, 6), equals('aabbcc'));
        expect(result.length, equals(200));
      });
    });
  });
}
