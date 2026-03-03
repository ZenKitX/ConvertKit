// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:convert_kit/convert_kit.dart';
import 'package:test/test.dart';

void main() {
  group('IdentityCodec', () {
    test('编码器应该返回输入本身', () {
      const identity = IdentityCodec<String>();
      expect(identity.encoder.convert('Hello'), equals('Hello'));
      expect(identity.encoder.convert('World'), equals('World'));
      expect(identity.encoder.convert(''), equals(''));
    });

    test('解码器应该返回输入本身', () {
      const identity = IdentityCodec<String>();
      expect(identity.decoder.convert('Hello'), equals('Hello'));
      expect(identity.decoder.convert('World'), equals('World'));
      expect(identity.decoder.convert(''), equals(''));
    });

    test('编码应该返回输入本身', () {
      const identity = IdentityCodec<String>();
      expect(identity.encode('test'), equals('test'));
    });

    test('解码应该返回输入本身', () {
      const identity = IdentityCodec<String>();
      expect(identity.decode('test'), equals('test'));
    });

    test('应该支持不同类型', () {
      // 字符串
      const stringIdentity = IdentityCodec<String>();
      expect(stringIdentity.encode('test'), equals('test'));

      // 整数
      const intIdentity = IdentityCodec<int>();
      expect(intIdentity.encode(42), equals(42));

      // 字节数组
      const bytesIdentity = IdentityCodec<List<int>>();
      final bytes = [1, 2, 3];
      expect(bytesIdentity.encode(bytes), same(bytes));
    });

    test('往返转换应该保持不变', () {
      const identity = IdentityCodec<String>();
      const original = 'Hello World';
      final encoded = identity.encode(original);
      final decoded = identity.decode(encoded);
      expect(decoded, equals(original));
      expect(identical(original, decoded), isTrue);
    });

    test('应该返回输入的引用而不是副本', () {
      const identity = IdentityCodec<List<int>>();
      final input = [1, 2, 3];
      final output = identity.encode(input);
      expect(identical(input, output), isTrue);
    });

    group('融合', () {
      test('与 HexCodec 融合应该返回 HexCodec', () {
        const identity = IdentityCodec<List<int>>();
        final fused = identity.fuse(hex);
        expect(identical(fused, hex), isTrue);
      });

      test('与 PercentCodec 融合应该返回 PercentCodec', () {
        const identity = IdentityCodec<List<int>>();
        final fused = identity.fuse(percent);
        expect(identical(fused, percent), isTrue);
      });

      test('融合后的编解码器应该正常工作', () {
        const identity = IdentityCodec<List<int>>();
        final fused = identity.fuse(hex);

        final original = [255, 254, 253];
        final encoded = fused.encode(original);
        expect(encoded, equals('fffefd'));

        final decoded = fused.decode(encoded);
        expect(decoded, equals(original));
      });

      test('多次融合应该正常工作', () {
        const identity1 = IdentityCodec<List<int>>();
        const identity2 = IdentityCodec<List<int>>();

        // identity1.fuse(identity2) 应该返回 identity2
        final fused1 = identity1.fuse(identity2);
        expect(identical(fused1, identity2), isTrue);

        // 然后与 hex 融合
        final fused2 = fused1.fuse(hex);
        expect(identical(fused2, hex), isTrue);
      });
    });

    group('边界情况', () {
      test('应该处理 null 值（如果类型允许）', () {
        const identity = IdentityCodec<String?>();
        expect(identity.encode(null), isNull);
        expect(identity.decode(null), isNull);
      });

      test('应该处理空集合', () {
        const identity = IdentityCodec<List<int>>();
        final empty = <int>[];
        expect(identity.encode(empty), same(empty));
      });

      test('应该处理复杂对象', () {
        const identity = IdentityCodec<Map<String, dynamic>>();
        final map = {'key': 'value', 'number': 42};
        expect(identity.encode(map), same(map));
      });

      test('应该保持对象的可变性', () {
        const identity = IdentityCodec<List<int>>();
        final list = [1, 2, 3];
        final encoded = identity.encode(list);

        // 修改原始列表
        list.add(4);

        // 编码后的列表也应该改变（因为是同一个引用）
        expect(encoded, equals([1, 2, 3, 4]));
      });
    });

    group('性能', () {
      test('应该是 O(1) 操作', () {
        const identity = IdentityCodec<String>();

        // 小字符串
        final small = 'a' * 10;
        final smallResult = identity.encode(small);
        expect(identical(small, smallResult), isTrue);

        // 大字符串
        final large = 'a' * 10000;
        final largeResult = identity.encode(large);
        expect(identical(large, largeResult), isTrue);
      });

      test('不应该分配额外内存', () {
        const identity = IdentityCodec<List<int>>();
        final input = List.generate(1000, (i) => i);
        final output = identity.encode(input);

        // 应该是同一个对象
        expect(identical(input, output), isTrue);
      });
    });

    group('类型安全', () {
      test('应该保持类型信息', () {
        const identity = IdentityCodec<String>();
        final result = identity.encode('test');
        expect(result, isA<String>());
      });

      test('不同类型的身份编解码器应该是不同的', () {
        const stringIdentity = IdentityCodec<String>();
        const intIdentity = IdentityCodec<int>();

        // 它们是不同的类型
        expect(
            stringIdentity.runtimeType, isNot(equals(intIdentity.runtimeType)));
      });
    });
  });
}
