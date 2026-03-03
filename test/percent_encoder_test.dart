// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:convert_kit/convert_kit.dart';
import 'package:test/test.dart';

void main() {
  group('PercentEncoder', () {
    test('不编码保留字符（unreserved characters）', () {
      final safeChars = 'abcdefghijklmnopqrstuvwxyz'
          'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
          '0123456789-._~';
      expect(
          percentEncoder.convert([...safeChars.codeUnits]), equals(safeChars));
    });

    test('编码保留的 ASCII 字符', () {
      expect(
        percentEncoder.convert([...' `{@[,/^}\x7f\x00%'.codeUnits]),
        equals('%20%60%7B%40%5B%2C%2F%5E%7D%7F%00%25'),
      );
    });

    test('编码非 ASCII 字符', () {
      expect(percentEncoder.convert([0x80, 0xFF]), equals('%80%FF'));
    });

    test('混合编码和未编码字符', () {
      expect(
        percentEncoder.convert([...'a+b=\x80'.codeUnits]),
        equals('a%2Bb%3D%80'),
      );
    });

    test('处理空数组', () {
      expect(percentEncoder.convert([]), equals(''));
    });

    test('处理单字节数组', () {
      expect(percentEncoder.convert([0x00]), equals('%00'));
      expect(percentEncoder.convert([0x41]), equals('A')); // 'A'
      expect(percentEncoder.convert([0x20]), equals('%20')); // 空格
    });

    test('编码所有特殊字符', () {
      // 测试一些常见的特殊字符
      expect(percentEncoder.convert([0x21]), equals('%21')); // !
      expect(percentEncoder.convert([0x23]), equals('%23')); // #
      expect(percentEncoder.convert([0x24]), equals('%24')); // $
      expect(percentEncoder.convert([0x26]), equals('%26')); // &
      expect(percentEncoder.convert([0x27]), equals('%27')); // '
      expect(percentEncoder.convert([0x28]), equals('%28')); // (
      expect(percentEncoder.convert([0x29]), equals('%29')); // )
      expect(percentEncoder.convert([0x2A]), equals('%2A')); // *
      expect(percentEncoder.convert([0x2B]), equals('%2B')); // +
      expect(percentEncoder.convert([0x2C]), equals('%2C')); // ,
      expect(percentEncoder.convert([0x2F]), equals('%2F')); // /
    });

    test('保留字符不编码', () {
      expect(percentEncoder.convert([0x2D]), equals('-')); // -
      expect(percentEncoder.convert([0x2E]), equals('.')); // .
      expect(percentEncoder.convert([0x5F]), equals('_')); // _
      expect(percentEncoder.convert([0x7E]), equals('~')); // ~
    });

    test('拒绝非字节值（大于 255）', () {
      expect(() => percentEncoder.convert([0x100]), throwsFormatException);
      expect(() => percentEncoder.convert([256]), throwsFormatException);
      expect(() => percentEncoder.convert([1000]), throwsFormatException);
    });

    test('拒绝负数值', () {
      expect(() => percentEncoder.convert([-1]), throwsFormatException);
      expect(() => percentEncoder.convert([-128]), throwsFormatException);
    });

    test('拒绝混合有效和无效字节', () {
      expect(
          () => percentEncoder.convert([65, 66, 256]), throwsFormatException);
      expect(
          () => percentEncoder.convert([0x100, 65, 66]), throwsFormatException);
    });

    group('分块转换', () {
      test('编码字节数组', () {
        final results = <String>[];
        final controller = StreamController<String>(sync: true);
        controller.stream.listen(results.add);
        final sink = percentEncoder.startChunkedConversion(controller.sink);

        sink.add([...'a+b=\x80'.codeUnits]);
        expect(results, equals(['a%2Bb%3D%80']));

        sink.add([0x00, 0x01, 0xfe, 0xff]);
        expect(results, equals(['a%2Bb%3D%80', '%00%01%FE%FF']));
      });

      test('处理空数组和单字节数组', () {
        final results = <String>[];
        final controller = StreamController<String>(sync: true);
        controller.stream.listen(results.add);
        final sink = percentEncoder.startChunkedConversion(controller.sink);

        sink.add([]);
        expect(results, equals(['']));

        sink.add([0x00]);
        expect(results, equals(['', '%00']));

        sink.add([]);
        expect(results, equals(['', '%00', '']));
      });

      test('使用 addSlice 方法', () {
        final results = <String>[];
        final controller = StreamController<String>(sync: true);
        controller.stream.listen(results.add);
        final sink = percentEncoder.startChunkedConversion(controller.sink);

        final data = [65, 66, 32, 67, 68]; // "AB CD"
        sink.addSlice(data, 0, 2, false); // "AB"
        expect(results, equals(['AB']));

        sink.addSlice(data, 2, 5, false); // " CD"
        expect(results, equals(['AB', '%20CD']));

        sink.close();
      });

      test('addSlice 的 isLast 参数自动关闭 sink', () {
        final results = <String>[];
        var closed = false;
        final controller = StreamController<String>(
          sync: true,
          onCancel: () => closed = true,
        );
        controller.stream.listen(results.add, onDone: () => closed = true);
        final sink = percentEncoder.startChunkedConversion(controller.sink);

        final data = [65, 66, 67]; // "ABC"
        sink.addSlice(data, 0, 3, true);
        expect(results, equals(['ABC']));
        expect(closed, isTrue);
      });

      test('拒绝非字节值', () {
        final sink = percentEncoder.startChunkedConversion(
          StreamController<String>(sync: true).sink,
        );
        expect(() => sink.add([0x100]), throwsFormatException);
        expect(() => sink.add([256]), throwsFormatException);
        expect(() => sink.add([-1]), throwsFormatException);
      });

      test('addSlice 验证范围', () {
        final sink = percentEncoder.startChunkedConversion(
          StreamController<String>(sync: true).sink,
        );
        final data = [65, 66, 67];

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
      test('编码所有字节值（0-255）', () {
        final allBytes = List.generate(256, (i) => i);
        final encoded = percentEncoder.convert(allBytes);

        // 验证结果不为空
        expect(encoded, isNotEmpty);

        // 验证保留字符未编码
        expect(encoded.contains('A'), isTrue);
        expect(encoded.contains('Z'), isTrue);
        expect(encoded.contains('a'), isTrue);
        expect(encoded.contains('z'), isTrue);
        expect(encoded.contains('0'), isTrue);
        expect(encoded.contains('9'), isTrue);
        expect(encoded.contains('-'), isTrue);
        expect(encoded.contains('.'), isTrue);
        expect(encoded.contains('_'), isTrue);
        expect(encoded.contains('~'), isTrue);

        // 验证包含百分号编码
        expect(encoded.contains('%'), isTrue);
      });

      test('大数据量编码', () {
        // 创建一个较大的字节数组
        final largeData = List.generate(10000, (i) => i % 256);
        final encoded = percentEncoder.convert(largeData);

        // 验证结果长度合理（至少与输入相同）
        expect(encoded.length, greaterThanOrEqualTo(largeData.length));
      });

      test('连续的特殊字符', () {
        final special = [0x20, 0x21, 0x22, 0x23, 0x24, 0x25];
        expect(
          percentEncoder.convert(special),
          equals('%20%21%22%23%24%25'),
        );
      });

      test('URL 查询字符串示例', () {
        // "name=John Doe&age=30"
        final query = [...'name=John Doe&age=30'.codeUnits];
        final encoded = percentEncoder.convert(query);
        expect(encoded, equals('name%3DJohn%20Doe%26age%3D30'));
      });
    });
  });
}
