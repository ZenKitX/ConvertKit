// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:convert_kit/convert_kit.dart';
import 'package:test/test.dart';

void main() {
  group('PercentCodec', () {
    test('编码器应该可以通过 codec 访问', () {
      expect(percent.encoder, isNotNull);
      expect(percent.encoder, isA<PercentEncoder>());
    });

    test('解码器应该可以通过 codec 访问', () {
      expect(percent.decoder, isNotNull);
      expect(percent.decoder, isA<PercentDecoder>());
    });

    group('编码', () {
      test('应该编码字节数组', () {
        expect(
          percent.encode([65, 66, 67, 32, 49, 50, 51]),
          equals('ABC%20123'),
        );
      });

      test('应该处理空数组', () {
        expect(percent.encode([]), equals(''));
      });

      test('应该编码特殊字符', () {
        expect(
          percent.encode([64, 33, 40, 41]),
          equals('%40%21%28%29'),
        );
      });
    });

    group('解码', () {
      test('应该解码百分号编码字符串', () {
        expect(
          percent.decode('ABC%20123'),
          equals([65, 66, 67, 32, 49, 50, 51]),
        );
      });

      test('应该处理空字符串', () {
        expect(percent.decode(''), equals([]));
      });

      test('应该解码特殊字符', () {
        expect(
          percent.decode('%40%21%28%29'),
          equals([64, 33, 40, 41]),
        );
      });
    });

    group('往返转换', () {
      test('编码后解码应该得到原始数据', () {
        final original = [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100];
        final encoded = percent.encode(original);
        final decoded = percent.decode(encoded);
        expect(decoded, equals(original));
      });

      test('应该处理所有字节值（0-255）', () {
        final original = List.generate(256, (i) => i);
        final encoded = percent.encode(original);
        final decoded = percent.decode(encoded);
        expect(decoded, equals(original));
      });

      test('应该处理保留字符', () {
        // A-Z, a-z, 0-9, -._~
        final original = [
          ...'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~'
              .codeUnits
        ];
        final encoded = percent.encode(original);
        final decoded = percent.decode(encoded);
        expect(decoded, equals(original));
      });

      test('应该处理混合内容', () {
        final original = [...'Hello World! Test'.codeUnits];
        final encoded = percent.encode(original);
        final decoded = percent.decode(encoded);
        expect(decoded, equals(original));
      });

      test('应该处理空字节', () {
        final original = [0, 1, 2, 3, 255, 254, 253];
        final encoded = percent.encode(original);
        final decoded = percent.decode(encoded);
        expect(decoded, equals(original));
      });

      test('应该处理大数据', () {
        final original = List.generate(10000, (i) => i % 256);
        final encoded = percent.encode(original);
        final decoded = percent.decode(encoded);
        expect(decoded, equals(original));
      });
    });

    group('流式处理', () {
      test('编码流应该正常工作', () async {
        final stream = Stream.fromIterable([
          [65, 66, 67],
          [32, 49, 50, 51],
        ]).transform(percent.encoder);

        final results = await stream.toList();
        expect(results, equals(['ABC', '%20123']));
      });

      test('解码流应该正常工作', () async {
        final stream = Stream.fromIterable([
          'ABC%2',
          '0',
          '123',
        ]).transform(percent.decoder);

        final results = await stream.toList();
        expect(results, hasLength(3));
        expect(results[0], equals([65, 66, 67]));
        expect(results[1], equals([32]));
        expect(results[2], equals([49, 50, 51]));
      });

      test('编码和解码流应该可以组合', () async {
        final original = [
          [72, 101, 108, 108, 111],
          [32, 87, 111, 114, 108, 100],
        ];

        final stream = Stream.fromIterable(original)
            .transform(percent.encoder)
            .transform(percent.decoder);

        final results = await stream.toList();
        expect(results, hasLength(2));
        expect(results[0], equals(original[0]));
        expect(results[1], equals(original[1]));
      });
    });

    group('实际应用场景', () {
      test('URL 查询参数编码', () {
        final params = [...'name=John Doe&age=30'.codeUnits];
        final encoded = percent.encode(params);
        expect(encoded, equals('name%3DJohn%20Doe%26age%3D30'));

        final decoded = percent.decode(encoded);
        expect(decoded, equals(params));
      });

      test('文件名编码', () {
        final filename = [...'document (1).pdf'.codeUnits];
        final encoded = percent.encode(filename);
        final decoded = percent.decode(encoded);
        expect(decoded, equals(filename));
      });

      test('特殊字符处理', () {
        final special = [...'!@#\$%^&*()_+-=[]{}|;:\'",.<>?/'.codeUnits];
        final encoded = percent.encode(special);
        final decoded = percent.decode(encoded);
        expect(decoded, equals(special));
      });
    });

    group('边界情况', () {
      test('单字节往返', () {
        for (var i = 0; i < 256; i++) {
          final original = [i];
          final encoded = percent.encode(original);
          final decoded = percent.decode(encoded);
          expect(decoded, equals(original), reason: '字节 $i 往返失败');
        }
      });

      test('连续相同字节', () {
        final original = List.filled(100, 65); // 100 个 'A'
        final encoded = percent.encode(original);
        final decoded = percent.decode(encoded);
        expect(decoded, equals(original));
      });

      test('交替字节模式', () {
        final original = List.generate(100, (i) => i % 2 == 0 ? 65 : 32);
        final encoded = percent.encode(original);
        final decoded = percent.decode(encoded);
        expect(decoded, equals(original));
      });
    });
  });
}
