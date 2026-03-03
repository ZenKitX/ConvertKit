// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// 通用工具函数。
///
/// 提供编解码过程中常用的辅助函数。
library;

import 'charcodes.dart';

/// 将十六进制字符转换为对应的数字值 (0-15)。
///
/// 从 [codeUnits] 列表的 [index] 位置读取一个字符编码，
/// 将其解析为十六进制数字。
///
/// 支持的字符：
/// - `0-9`: 返回 0-9
/// - `A-F`: 返回 10-15
/// - `a-f`: 返回 10-15
///
/// ## 参数
///
/// - [codeUnits]: 字符编码列表
/// - [index]: 要解析的字符位置
///
/// ## 返回值
///
/// 返回 0-15 之间的整数。
///
/// ## 异常
///
/// 如果字符不是有效的十六进制字符，抛出 [FormatException]。
///
/// ## 使用示例
///
/// ```dart
/// final codes = '3F'.codeUnits;
/// final digit1 = digitForCodeUnit(codes, 0); // 3
/// final digit2 = digitForCodeUnit(codes, 1); // 15
/// ```
///
/// ## 实现说明
///
/// 使用位运算优化性能：
/// - 对于数字字符 (0-9)：使用 XOR 运算快速计算
/// - 对于字母字符 (A-F/a-f)：使用 OR 运算统一转为小写
int digitForCodeUnit(List<int> codeUnits, int index) {
  // 获取字符编码
  final codeUnit = codeUnits[index];

  // 尝试解析为数字 (0-9)
  // XOR 运算的原理：ASCII 中 '0' 是 0b110000 (0x30)
  // '0' ^ '0' = 0, '1' ^ '0' = 1, ..., '9' ^ '0' = 9
  final digit = $0 ^ codeUnit;
  if (digit <= 9) {
    if (digit >= 0) return digit;
  } else {
    // 尝试解析为字母 (A-F 或 a-f)
    // OR 0x20 将大写字母转为小写
    // 因为大写字母比小写字母的 ASCII 码小 0x20
    final letter = 0x20 | codeUnit;
    if ($a <= letter && letter <= $f) {
      return letter - $a + 10;
    }
  }

  // 无效的十六进制字符
  throw FormatException(
    '无效的十六进制字符 '
    "U+${codeUnit.toRadixString(16).padLeft(4, '0')}",
    codeUnits,
    index,
  );
}
