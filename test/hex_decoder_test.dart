// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:convert_kit/src/byte_accumulator_sink.dart';
import 'package:convert_kit/src/hex/decoder.dart';
import 'package:test/test.dart';

void main() {
  group('HexDecoder', () {
    late HexDecoder decoder;

    setUp(() {
      decoder = hexDecoder;
    });

    group('基本解码', () {
      test('应该解码空字符串', () {
        expect(decoder.convert(''), equals([]));
      });

      test('应该解码单个字节', () {
        expect(decoder.convert('00'), equals([0]));
        expect(decoder.convert('0f'), equals([15]));
        expect(decoder.convert('10'), equals([16]));
        expect(decoder.convert('ff'), equals([255]));
      });

      test('应该解码多个字节', () {
        expect(decoder.convert('000102'), equals([0, 1, 2]));
        expect(decoder.convert('fffefd'), equals([255, 254, 253]));
        expect(decoder.convert('0a141e'), equals([10, 20, 30]));
      });

      test('应该支持大写字母', () {
        expect(decoder.convert('ABCDEF'), equals([0xAB, 0xCD, 0xEF]));
      });

      test('应该支持大小写混合', () {
        expect(decoder.convert('AbCdEf'), equals([0xAB, 0xCD, 0xEF]));
        expect(decoder.convert('FfFeFd'), equals([255, 254, 253]));
      });

      test('应该正确解码所有字节值', () {
        // 测试 0-255 的所有值
        for (var i = 0; i < 256; i++) {
          final hex = i.toRadixString(16).padLeft(2, '0');
          expect(decoder.convert(hex), equals([i]));
        }
      });
    });

    group('边界情况', () {
      test('应该解码最小值', () {
        expect(decoder.convert('00'), equals([0]));
      });

      test('应该解码最大值', () {
        expect(decoder.convert('ff'), equals([255]));
      });

      test('应该解码连续的相同字节', () {
        expect(decoder.convert('000000'), equals([0, 0, 0]));
        expect(decoder.convert('ffffff'), equals([255, 255, 255]));
      });

      test('应该解码大量字节', () {
        final hex = List.generate(1000, (i) {
          return (i % 256).toRadixString(16).padLeft(2, '0');
        }).join();

        final result = decoder.convert(hex);

        expect(result.length, equals(1000));
        expect(result[0], equals(0));
        expect(result[1], equals(1));
        expect(result[2], equals(2));
      });
    });

    group('异常处理', () {
      test('应该在输入长度为奇数时抛出异常', () {
        expect(
          () => decoder.convert('f'),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => decoder.convert('fff'),
          throwsA(isA<FormatException>()),
        );
      });

      test('应该在包含无效字符时抛出异常', () {
        expect(
          () => decoder.convert('zz'),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => decoder.convert('0g'),
          throwsA(isA<FormatException>()),
        );
      });

      test('应该在包含空格时抛出异常', () {
        expect(
          () => decoder.convert('00 11'),
          throwsA(isA<FormatException>()),
        );
      });

      test('异常应该包含有用的错误信息', () {
        try {
          decoder.convert('fff');
          fail('应该抛出异常');
        } on FormatException catch (e) {
          expect(e.message, contains('输入长度无效'));
          expect(e.message, contains('偶数'));
        }
      });
    });

    group('分块转换', () {
      test('应该支持分块解码', () {
        final sink = ByteAccumulatorSink();
        final conversionSink = decoder.startChunkedConversion(sink);

        conversionSink.add('010203');
        conversionSink.add('040506');
        conversionSink.close();

        expect(sink.bytes, equals([1, 2, 3, 4, 5, 6]));
      });

      test('应该支持在奇数位置分块', () {
        final sink = ByteAccumulatorSink();
        final conversionSink = decoder.startChunkedConversion(sink);

        // 在奇数位置分块
        conversionSink.add('010');
        conversionSink.add('203');
        conversionSink.close();

        expect(sink.bytes, equals([1, 2, 3]));
      });

      test('应该支持 addSlice', () {
        final sink = ByteAccumulatorSink();
        final conversionSink = decoder.startChunkedConversion(sink);

        const data = '010203040506';
        conversionSink.addSlice(data, 0, 6, false);
        conversionSink.addSlice(data, 6, 12, true);

        expect(sink.bytes, equals([1, 2, 3, 4, 5, 6]));
        sink.close();
      });

      test('addSlice 的 isLast 应该关闭 sink', () {
        final sink = ByteAccumulatorSink();
        final conversionSink = decoder.startChunkedConversion(sink);

        conversionSink.addSlice('010203', 0, 6, true);

        expect(sink.bytes, equals([1, 2, 3]));
        expect(sink.isClosed, isTrue);
      });

      test('应该处理空块', () {
        final sink = ByteAccumulatorSink();
        final conversionSink = decoder.startChunkedConversion(sink);

        conversionSink.add('');
        conversionSink.add('0102');
        conversionSink.add('');
        conversionSink.close();

        expect(sink.bytes, equals([1, 2]));
      });

      test('应该在分块结束时有不完整字节时抛出异常', () {
        final sink = ByteAccumulatorSink();
        final conversionSink = decoder.startChunkedConversion(sink);

        conversionSink.add('01');
        conversionSink.add('0');

        expect(
          () => conversionSink.close(),
          throwsA(isA<FormatException>()),
        );
        sink.close();
      });

      test('应该验证 addSlice 的范围', () {
        final sink = ByteAccumulatorSink();
        final conversionSink = decoder.startChunkedConversion(sink);

        expect(
          () => conversionSink.addSlice('0102', 0, 5, false),
          throwsA(isA<RangeError>()),
        );
        conversionSink.close();
        sink.close();
      });
    });

    group('与编码器互操作', () {
      test('应该能解码编码器的输出', () {
        final original = [0, 1, 2, 255, 254, 253];
        final hex =
            original.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        final decoded = decoder.convert(hex);

        expect(decoded, equals(original));
      });

      test('应该处理 ASCII 字符的字节值', () {
        // 'ABC' = [65, 66, 67]
        final decoded = decoder.convert('414243');
        expect(decoded, equals([65, 66, 67]));
        expect(String.fromCharCodes(decoded), equals('ABC'));
      });

      test('应该处理 UTF-8 字节序列', () {
        final original = utf8.encode('你好');
        final hex =
            original.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        final decoded = decoder.convert(hex);

        expect(decoded, equals(original));
        expect(utf8.decode(decoded), equals('你好'));
      });
    });

    group('特殊模式', () {
      test('应该解码二进制数据', () {
        expect(decoder.convert('00ff00ff'), equals([0x00, 0xFF, 0x00, 0xFF]));
      });

      test('应该解码递增序列', () {
        expect(decoder.convert('000102030405'), equals([0, 1, 2, 3, 4, 5]));
      });

      test('应该解码递减序列', () {
        expect(decoder.convert('050403020100'), equals([5, 4, 3, 2, 1, 0]));
      });

      test('应该解码重复模式', () {
        expect(decoder.convert('aabbccaabbcc'),
            equals([0xAA, 0xBB, 0xCC, 0xAA, 0xBB, 0xCC]));
      });
    });

    group('性能相关', () {
      test('应该高效处理大数据', () {
        final hex = List.generate(10000, (i) {
          return (i % 256).toRadixString(16).padLeft(2, '0');
        }).join();

        final result = decoder.convert(hex);

        expect(result.length, equals(10000));
      });

      test('应该正确处理重复模式', () {
        const pattern = 'aabbcc';
        final repeated = pattern * 100;
        final result = decoder.convert(repeated);

        expect(result.length, equals(300));
        // 验证模式重复
        expect(result.sublist(0, 3), equals([0xAA, 0xBB, 0xCC]));
      });
    });

    group('UTF-8 字节 sink', () {
      test('应该支持从 UTF-8 字节解码', () {
        final sink = ByteAccumulatorSink();
        final conversionSink = decoder.startChunkedConversion(sink);
        final byteSink = conversionSink.asUtf8Sink(false);

        // '0102' 的 UTF-8 字节
        byteSink.add('0102'.codeUnits);
        byteSink.close();

        expect(sink.bytes, equals([1, 2]));
        sink.close();
      });

      test('应该在 UTF-8 字节 sink 中处理奇数位置分块', () {
        final sink = ByteAccumulatorSink();
        final conversionSink = decoder.startChunkedConversion(sink);
        final byteSink = conversionSink.asUtf8Sink(false);

        byteSink.add('010'.codeUnits);
        byteSink.add('203'.codeUnits);
        byteSink.close();

        expect(sink.bytes, equals([1, 2, 3]));
        sink.close();
      });
    });
  });
}
