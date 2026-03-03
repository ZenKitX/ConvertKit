// Copyright (c) 2026, ConvertKit Contributors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// 常用字符的 ASCII 码常量。
///
/// 这些常量用于在编解码过程中进行字符比较和判断，
/// 使用整数比较比字符串操作更高效。
///
/// ## 使用示例
///
/// ```dart
/// // 判断是否为数字字符
/// bool isDigit(int charCode) {
///   return charCode >= $0 && charCode <= $9;
/// }
///
/// // 判断是否为小写字母
/// bool isLowerCase(int charCode) {
///   return charCode >= $a && charCode <= $z;
/// }
/// ```
library;

/// 字符 `%` 的 ASCII 码 (0x25)。
///
/// 用于百分号编码。
const int $percent = 0x25;

/// 字符 `-` 的 ASCII 码 (0x2d)。
///
/// 连字符，URL 中的保留字符之一。
const int $dash = 0x2d;

/// 字符 `.` 的 ASCII 码 (0x2e)。
///
/// 点号，URL 中的保留字符之一。
const int $dot = 0x2e;

/// 字符 `0` 的 ASCII 码 (0x30)。
///
/// 数字字符的起始位置。
const int $0 = 0x30;

/// 字符 `9` 的 ASCII 码 (0x39)。
///
/// 数字字符的结束位置。
const int $9 = 0x39;

/// 字符 `A` 的 ASCII 码 (0x41)。
///
/// 大写字母的起始位置。
const int $A = 0x41;

/// 字符 `F` 的 ASCII 码 (0x46)。
///
/// 十六进制大写字母的结束位置。
const int $F = 0x46;

/// 字符 `Z` 的 ASCII 码 (0x5A)。
///
/// 大写字母的结束位置。
const int $Z = 0x5A;

/// 字符 `_` 的 ASCII 码 (0x5f)。
///
/// 下划线，URL 中的保留字符之一。
const int $underscore = 0x5f;

/// 字符 `a` 的 ASCII 码 (0x61)。
///
/// 小写字母的起始位置。
const int $a = 0x61;

/// 字符 `f` 的 ASCII 码 (0x66)。
///
/// 十六进制小写字母的结束位置。
const int $f = 0x66;

/// 字符 `z` 的 ASCII 码 (0x7a)。
///
/// 小写字母的结束位置。
const int $z = 0x7a;

/// 字符 `~` 的 ASCII 码 (0x7e)。
///
/// 波浪号，URL 中的保留字符之一。
const int $tilde = 0x7e;
