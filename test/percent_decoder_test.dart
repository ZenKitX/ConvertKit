// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:convert_kit/convert_kit.dart';
import 'package:test/test.dart';

void main() {
  group('PercentDecoder', () {
    test('将百分号编码字符串转换为字节数组', () {
      expect(
        percentDecoder.convert('a%2Bb%3D%801'),
        equals([...'a+b=\x801'.codeUnits]),
      );
    });

    test('支持小写字母', () {
      expect(
        percentDecoder.convert('a%2bb%3d%80'),
        equals([...'a+b=\x80'.codeUnits]),
      );
    });

    test('支持更激进的编码', () {
      expect(
        percentDecoder.convert('%61%2E%5A'),
        equals([...'a.Z'.codeUnits]),
      );
    });

    test('支持较少的编码', () {
      const chars = ' `{@[,/^}\x7F\x00';
      expect(percentDecoder.convert(chars), equals([...chars.codeUnits]));
    });

    test('处理空字符串', () {
      expect(percentDecoder.convert(''), equals([]));
    });

    test('处理纯文本（无编码）', () {
      expect(
        percentDecoder.convert('Hello'),
        equals([72, 101, 108, 108, 111]),
      );
    });

    test('处理纯百分号编码', () {
      expect(
        percentDecoder.convert('%48%65%6C%6C%6F'),
        equals([72, 101, 108, 108, 111]),
      );
    });

    test('混合编码和未编码字符', () {
      expect(
        percentDecoder.convert('Hello%20World'),
        equals([...'Hello World'.codeUnits]),
      );
    });

    test('解码所有字节值（0-255）', () {
      // 创建包含所有字节值的编码字符串
      final encoded = List.generate(256, (i) {
        final hex = i.toRadixString(16).padLeft(2, '0').toUpperCase();
        return '%$hex';
      }).join();

      final decoded = percentDecoder.convert(encoded);
      expect(decoded, equals(List.generate(256, (i) => i)));
    });

    test('拒绝非 ASCII 字符 "\\u0141"', () {
      expect(() => percentDecoder.convert('a\u0141'), throwsFormatException);
      expect(() => percentDecoder.convert('\u0141a'), throwsFormatException);
    });

    test('拒绝非 ASCII 字符 "\\u{10041}"', () {
      expect(() => percentDecoder.convert('a\u{10041}'), throwsFormatException);
      expect(() => percentDecoder.convert('\u{10041}a'), throwsFormatException);
    });

    test('拒绝 % 后跟非十六进制字符', () {
      expect(() => percentDecoder.convert('%z2'), throwsFormatException);
      expect(() => percentDecoder.convert('%2z'), throwsFormatException);
      expect(() => percentDecoder.convert('%gg'), throwsFormatException);
    });

    test('拒绝以 % 结尾', () {
      expect(() => percentDecoder.convert('ab%'), throwsFormatException);
      expect(() => percentDecoder.convert('%'), throwsFormatException);
    });

    test('拒绝以不完整的编码结尾', () {
      expect(() => percentDecoder.convert('ab%2'), throwsFormatException);
      expect(() => percentDecoder.convert('%2'), throwsFormatException);
    });

    group('分块转换', () {
      late List<List<int>> results;
      late StringConversionSink sink;

      setUp(() {
        results = [];
        final controller = StreamController<List<int>>(sync: true);
        controller.stream.listen(results.add);
        sink = percentDecoder.startChunkedConversion(controller.sink);
      });

      test('将百分号编码转换为字节数组', () {
        sink.add('a%2Bb%3D%801');
        expect(
          results,
          equals([
            [...'a+b=\x801'.codeUnits],
          ]),
        );

        sink.add('%00%01%FE%FF');
        expect(
          results,
          equals([
            [...'a+b=\x801'.codeUnits],
            [0x00, 0x01, 0xfe, 0xff],
          ]),
        );
      });

      test('支持跨块分割的尾部百分号和数字', () {
        sink.add('ab%');
        expect(
          results,
          equals([
            [...'ab'.codeUnits],
          ]),
        );

        sink.add('2');
        expect(
          results,
          equals([
            [...'ab'.codeUnits],
          ]),
        );

        sink.add('0cd%2');
        expect(
          results,
          equals([
            [...'ab'.codeUnits],
            [...' cd'.codeUnits],
          ]),
        );

        sink.add('0');
        expect(
          results,
          equals([
            [...'ab'.codeUnits],
            [...' cd'.codeUnits],
            [...' '.codeUnits],
          ]),
        );
      });

      test('支持空字符串', () {
        sink.add('');
        expect(results, isEmpty);

        sink.add('%');
        expect(results, equals([<Never>[]]));

        sink.add('');
        expect(results, equals([<Never>[]]));

        sink.add('2');
        expect(results, equals([<Never>[]]));

        sink.add('');
        expect(results, equals([<Never>[]]));

        sink.add('0');
        expect(
          results,
          equals([
            <Never>[],
            [0x20],
          ]),
        );
      });

      test('在 close() 中检测到尾部 % 时拒绝', () {
        sink.add('ab%');
        expect(
          results,
          equals([
            [...'ab'.codeUnits],
          ]),
        );
        expect(() => sink.close(), throwsFormatException);
      });

      test('在 close() 中检测到尾部数字时拒绝', () {
        sink.add('ab%2');
        expect(
          results,
          equals([
            [...'ab'.codeUnits],
          ]),
        );
        expect(() => sink.close(), throwsFormatException);
      });

      test('在 addSlice() 中检测到尾部 % 时拒绝', () {
        sink.addSlice('ab%', 0, 3, false);
        expect(
          results,
          equals([
            [...'ab'.codeUnits],
          ]),
        );

        expect(() => sink.addSlice('ab%', 0, 3, true), throwsFormatException);
      });

      test('在 addSlice() 中检测到尾部数字时拒绝', () {
        sink.addSlice('ab%2', 0, 3, false);
        expect(
          results,
          equals([
            [...'ab'.codeUnits],
          ]),
        );

        expect(() => sink.addSlice('ab%2', 0, 3, true), throwsFormatException);
      });

      test('使用 addSlice 方法', () {
        const data1 = 'AB%20';
        const data2 = 'CD';

        sink.addSlice(data1, 0, 5, false); // "AB%20"
        expect(
          results,
          equals([
            [65, 66, 32],
          ]),
        );

        sink.addSlice(data2, 0, 2, false); // "CD"
        expect(
          results,
          equals([
            [65, 66, 32],
            [67, 68],
          ]),
        );

        sink.close();
      });

      test('addSlice 验证范围', () {
        final data = 'ABC';

        // 有效范围
        expect(() => sink.addSlice(data, 0, 3, false), returnsNormally);
        expect(() => sink.addSlice(data, 1, 2, false), returnsNormally);

        // 无效范围
        expect(() => sink.addSlice(data, -1, 2, false), throwsRangeError);
        expect(() => sink.addSlice(data, 0, 4, false), throwsRangeError);
        expect(() => sink.addSlice(data, 2, 1, false), throwsRangeError);
      });
    });

    group('边界情况', () {
      test('连续的百分号编码', () {
        expect(
          percentDecoder.convert('%20%21%22%23'),
          equals([0x20, 0x21, 0x22, 0x23]),
        );
      });

      test('URL 查询字符串示例', () {
        final encoded = 'name%3DJohn%20Doe%26age%3D30';
        final decoded = percentDecoder.convert(encoded);
        expect(decoded, equals([...'name=John Doe&age=30'.codeUnits]));
      });

      test('大数据量解码', () {
        // 创建一个较大的编码字符串
        final encoded = List.generate(1000, (i) {
          final byte = i % 256;
          final hex = byte.toRadixString(16).padLeft(2, '0').toUpperCase();
          return '%$hex';
        }).join();

        final decoded = percentDecoder.convert(encoded);
        expect(decoded.length, equals(1000));
        expect(decoded, equals(List.generate(1000, (i) => i % 256)));
      });

      test('处理 %00（空字节）', () {
        expect(percentDecoder.convert('%00'), equals([0]));
        expect(percentDecoder.convert('a%00b'), equals([97, 0, 98]));
      });

      test('处理 %FF（最大字节）', () {
        expect(percentDecoder.convert('%FF'), equals([255]));
        expect(percentDecoder.convert('a%FFb'), equals([97, 255, 98]));
      });
    });

    group('UTF-8 字节 sink', () {
      test('支持从 UTF-8 字节解码', () {
        final results = <List<int>>[];
        final controller = StreamController<List<int>>(sync: true);
        controller.stream.listen(results.add);

        final sink = percentDecoder.startChunkedConversion(controller.sink);
        final byteSink = sink.asUtf8Sink(false);

        byteSink.add([...'a%2Bb'.codeUnits]);
        expect(
          results,
          equals([
            [...'a+b'.codeUnits],
          ]),
        );

        byteSink.close();
      });

      test('在 UTF-8 字节 sink 中处理跨块分割', () {
        final results = <List<int>>[];
        final controller = StreamController<List<int>>(sync: true);
        controller.stream.listen(results.add);

        final sink = percentDecoder.startChunkedConversion(controller.sink);
        final byteSink = sink.asUtf8Sink(false);

        byteSink.add([...'ab%2'.codeUnits]);
        expect(
          results,
          equals([
            [...'ab'.codeUnits],
          ]),
        );

        byteSink.add([...'0'.codeUnits]);
        expect(
          results,
          equals([
            [...'ab'.codeUnits],
            [32],
          ]),
        );

        byteSink.add([...'c'.codeUnits]);
        expect(
          results,
          equals([
            [...'ab'.codeUnits],
            [32],
            [99],
          ]),
        );

        byteSink.close();
      });
    });
  });
}
