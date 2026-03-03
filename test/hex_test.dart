// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:convert_kit/src/hex.dart';
import 'package:test/test.dart';

void main() {
  group('HexCodec', () {
    group('编码器', () {
      test('应该将字节数组转换为十六进制', () {
        expect(hex.encode([0x1a, 0xb2, 0x3c, 0xd4]), equals('1ab23cd4'));
        expect(hex.encode([0x00, 0x01, 0xfe, 0xff]), equals('0001feff'));
      });

      test('应该处理空数组', () {
        expect(hex.encode([]), equals(''));
      });

      test('应该处理单字节', () {
        expect(hex.encode([0x00]), equals('00'));
        expect(hex.encode([0xff]), equals('ff'));
      });

      group('分块转换', () {
        test('应该将字节数组转换为十六进制', () {
          final results = <String>[];
          final controller = StreamController<String>(sync: true);
          controller.stream.listen(results.add);
          final sink = hex.encoder.startChunkedConversion(controller.sink);

          sink.add([0x1a, 0xb2, 0x3c, 0xd4]);
          expect(results, equals(['1ab23cd4']));

          sink.add([0x00, 0x01, 0xfe, 0xff]);
          expect(results, equals(['1ab23cd4', '0001feff']));

          controller.close();
        });

        test('应该处理空列表和单字节列表', () {
          final results = <String>[];
          final controller = StreamController<String>(sync: true);
          controller.stream.listen(results.add);
          final sink = hex.encoder.startChunkedConversion(controller.sink);

          sink.add([]);
          expect(results, equals(['']));

          sink.add([0x00]);
          expect(results, equals(['', '00']));

          sink.add([]);
          expect(results, equals(['', '00', '']));

          controller.close();
        });
      });

      test('应该拒绝非字节值', () {
        expect(() => hex.encode([0x100]), throwsFormatException);

        final sink = hex.encoder.startChunkedConversion(
          StreamController(sync: true),
        );
        expect(() => sink.add([0x100]), throwsFormatException);
      });
    });

    group('解码器', () {
      test('应该将十六进制转换为字节数组', () {
        expect(hex.decode('1ab23cd4'), equals([0x1a, 0xb2, 0x3c, 0xd4]));
        expect(hex.decode('0001feff'), equals([0x00, 0x01, 0xfe, 0xff]));
      });

      test('应该支持大写字母', () {
        expect(
          hex.decode('0123456789ABCDEFabcdef'),
          equals([
            0x01,
            0x23,
            0x45,
            0x67,
            0x89,
            0xab,
            0xcd,
            0xef,
            0xab,
            0xcd,
            0xef,
          ]),
        );
      });

      test('应该处理空字符串', () {
        expect(hex.decode(''), equals([]));
      });

      group('分块转换', () {
        late List<List<int>> results;
        late StringConversionSink sink;

        setUp(() {
          results = [];
          final controller = StreamController<List<int>>(sync: true);
          controller.stream.listen(results.add);
          sink = hex.decoder.startChunkedConversion(controller.sink);
        });

        test('应该将十六进制转换为字节数组', () {
          sink.add('1ab23cd4');
          expect(
            results,
            equals([
              [0x1a, 0xb2, 0x3c, 0xd4],
            ]),
          );

          sink.add('0001feff');
          expect(
            results,
            equals([
              [0x1a, 0xb2, 0x3c, 0xd4],
              [0x00, 0x01, 0xfe, 0xff],
            ]),
          );
        });

        test('应该支持跨块分割的尾部数字', () {
          sink.add('1ab23');
          expect(
            results,
            equals([
              [0x1a, 0xb2],
            ]),
          );

          sink.add('cd');
          expect(
            results,
            equals([
              [0x1a, 0xb2],
              [0x3c],
            ]),
          );

          sink.add('40001');
          expect(
            results,
            equals([
              [0x1a, 0xb2],
              [0x3c],
              [0xd4, 0x00, 0x01],
            ]),
          );

          sink.add('feff');
          expect(
            results,
            equals([
              [0x1a, 0xb2],
              [0x3c],
              [0xd4, 0x00, 0x01],
              [0xfe, 0xff],
            ]),
          );
        });

        test('应该支持空字符串', () {
          sink.add('');
          expect(results, isEmpty);

          sink.add('0');
          expect(results, equals([<Never>[]]));

          sink.add('');
          expect(results, equals([<Never>[]]));

          sink.add('0');
          expect(
            results,
            equals([
              <Never>[],
              [0x00],
            ]),
          );

          sink.add('');
          expect(
            results,
            equals([
              <Never>[],
              [0x00],
            ]),
          );
        });

        test('应该在 close() 中检测到奇数长度时拒绝', () {
          sink.add('1ab23');
          expect(
            results,
            equals([
              [0x1a, 0xb2],
            ]),
          );
          expect(() => sink.close(), throwsFormatException);
        });

        test('应该在 addSlice() 中检测到奇数长度时拒绝', () {
          sink.addSlice('1ab23cd', 0, 5, false);
          expect(
            results,
            equals([
              [0x1a, 0xb2],
            ]),
          );

          expect(
            () => sink.addSlice('1ab23cd', 5, 7, true),
            throwsFormatException,
          );
        });
      });

      group('应该拒绝非十六进制字符', () {
        for (final char in [
          'g',
          'G',
          '/',
          ':',
          '@',
          '`',
          '\x00',
          '\u0141',
          '\u{10041}',
        ]) {
          test('"$char"', () {
            expect(() => hex.decode('a$char'), throwsFormatException);
            expect(() => hex.decode('${char}a'), throwsFormatException);

            final sink = hex.decoder.startChunkedConversion(
              StreamController(sync: true),
            );
            expect(() => sink.add(char), throwsFormatException);
          });
        }
      });

      test('应该在 convert() 中检测到奇数长度时拒绝', () {
        expect(() => hex.decode('1ab23cd'), throwsFormatException);
      });
    });

    group('编解码器互操作', () {
      test('解码应该是编码的逆操作', () {
        final original = [0, 1, 2, 255, 254, 253, 128, 127];
        final encoded = hex.encode(original);
        final decoded = hex.decode(encoded);

        expect(decoded, equals(original));
      });

      test('编码应该是解码的逆操作', () {
        const original = '0001feff80';
        final decoded = hex.decode(original);
        final encoded = hex.encode(decoded);

        expect(encoded, equals(original));
      });

      test('应该处理所有字节值的往返转换', () {
        final allBytes = List.generate(256, (i) => i);
        final encoded = hex.encode(allBytes);
        final decoded = hex.decode(encoded);

        expect(decoded, equals(allBytes));
      });
    });

    group('与 UTF-8 组合', () {
      test('应该与 UTF-8 编码器组合', () {
        final utf8Hex = utf8.fuse(hex);

        final encoded = utf8Hex.encode('Hello');
        expect(encoded, equals('48656c6c6f'));

        final decoded = utf8Hex.decode('48656c6c6f');
        expect(decoded, equals('Hello'));
      });

      test('应该处理 Unicode 字符', () {
        final utf8Hex = utf8.fuse(hex);

        final encoded = utf8Hex.encode('你好世界');
        final decoded = utf8Hex.decode(encoded);

        expect(decoded, equals('你好世界'));
      });

      test('应该处理 Emoji', () {
        final utf8Hex = utf8.fuse(hex);

        final encoded = utf8Hex.encode('Hello 🌍');
        final decoded = utf8Hex.decode(encoded);

        expect(decoded, equals('Hello 🌍'));
      });
    });

    group('实际应用场景', () {
      test('应该处理哈希值', () {
        // 模拟 SHA-256 哈希值
        final hash = [
          0xe3,
          0xb0,
          0xc4,
          0x42,
          0x98,
          0xfc,
          0x1c,
          0x14,
          0x9a,
          0xfb,
          0xf4,
          0xc8,
          0x99,
          0x6f,
          0xb9,
          0x24,
          0x27,
          0xae,
          0x41,
          0xe4,
          0x64,
          0x9b,
          0x93,
          0x4c,
          0xa4,
          0x95,
          0x99,
          0x1b,
          0x78,
          0x52,
          0xb8,
          0x55,
        ];

        final hexHash = hex.encode(hash);
        expect(hexHash.length, equals(64)); // SHA-256 是 32 字节 = 64 个十六进制字符

        final decoded = hex.decode(hexHash);
        expect(decoded, equals(hash));
      });

      test('应该处理 MAC 地址', () {
        const macAddress = 'a1b2c3d4e5f6';
        final bytes = hex.decode(macAddress);

        expect(bytes, equals([0xa1, 0xb2, 0xc3, 0xd4, 0xe5, 0xf6]));
        expect(hex.encode(bytes), equals(macAddress));
      });

      test('应该处理颜色值', () {
        // RGB 颜色 #FF5733
        const colorHex = 'ff5733';
        final rgb = hex.decode(colorHex);

        expect(rgb, equals([255, 87, 51]));
        expect(hex.encode(rgb), equals(colorHex));
      });

      test('应该处理二进制数据', () {
        final binaryData = [0x00, 0xff, 0x00, 0xff, 0xaa, 0x55];
        final hexData = hex.encode(binaryData);

        expect(hexData, equals('00ff00ffaa55'));

        final decoded = hex.decode(hexData);
        expect(decoded, equals(binaryData));
      });
    });

    group('性能测试', () {
      test('应该高效处理大数据', () {
        final largeData = List.generate(10000, (i) => i % 256);
        final encoded = hex.encode(largeData);
        final decoded = hex.decode(encoded);

        expect(decoded, equals(largeData));
        expect(encoded.length, equals(20000));
      });

      test('应该高效处理重复模式', () {
        final pattern = [0xaa, 0xbb, 0xcc];
        final repeated = List.generate(1000, (i) => pattern[i % 3]).toList();

        final encoded = hex.encode(repeated);
        final decoded = hex.decode(encoded);

        expect(decoded, equals(repeated));
      });
    });
  });
}
