# Convert Package 调研报告

## 项目概述

**项目名称**: convert  
**版本**: 3.1.3-wip  
**维护者**: Dart 官方团队  
**仓库**: https://github.com/dart-lang/core/tree/main/pkgs/convert  
**许可证**: BSD-3-Clause

Convert 是 Dart 官方维护的数据转换工具包，作为 `dart:convert` 标准库的外部扩展，提供了更灵活的版本控制和一些非核心但实用的编解码器。

## 核心功能模块

### 1. 十六进制编解码 (Hex Codec)

**文件位置**: `lib/src/hex.dart`

**功能描述**:
- 实现 RFC 4648 Base16 规范
- 将字节数组与十六进制字符串相互转换
- 提供 `HexEncoder` 和 `HexDecoder`

**使用场景**:
- 二进制数据的可读化展示
- 加密哈希值的字符串表示
- 网络协议中的数据编码

**API 示例**:
```dart
import 'package:convert/convert.dart';

// 编码
final bytes = [255, 254, 253];
final hexString = hex.encode(bytes); // "fffefd"

// 解码
final decoded = hex.decode("fffefd"); // [255, 254, 253]
```

### 2. 百分号编码 (Percent Encoding)

**文件位置**: `lib/src/percent.dart`

**功能描述**:
- 实现 RFC 3986 URL 编码规范
- 字节数组与百分号编码字符串的转换
- 与 `Uri.encodeQueryComponent` 类似，但不将空格编码为 `+`

**特点**:
- 编码器：仅保留 ASCII 字母、数字和 `-._~` 字符
- 解码器：最大灵活性，可解码任何百分号编码的字节

**使用场景**:
- URL 参数编码
- HTTP 请求体编码
- 文件名安全化

**API 示例**:
```dart
import 'dart:convert';
import 'package:convert/convert.dart';

// 与 UTF-8 组合使用
final fusedCodec = utf8.fuse(percent);
final encoded = fusedCodec.encode('ABC 123 @!(');
// 输出: "ABC%20123%20%40%21%28"
```

### 3. 代码页编码 (CodePage)

**文件位置**: `lib/src/codepage.dart`

**功能描述**:
- 单字节字符编码实现
- 支持多种 ISO-8859 系列编码

**支持的编码**:
- `latin2` - ISO-8859-2 (东欧)
- `latin3` - ISO-8859-3 (南欧)
- `latin4` - ISO-8859-4 (北欧)
- `latinCyrillic` - ISO-8859-5 (西里尔)
- `latinArabic` - ISO-8859-6 (阿拉伯)
- `latinGreek` - ISO-8859-7 (希腊)
- `latinHebrew` - ISO-8859-8 (希伯来)
- `latin5` - ISO-8859-9 (土耳其)
- `latin6` - ISO-8859-10 (北欧)
- `latinThai` - ISO-8859-11 (泰语)
- `latin7` - ISO-8859-13 (波罗的海)
- `latin8` - ISO-8859-14 (凯尔特)
- `latin9` - ISO-8859-15 (西欧修订版)
- `latin10` - ISO-8859-16 (东南欧)

**使用场景**:
- 处理遗留系统数据
- 多语言文本转换
- 特定地区字符集支持

**API 示例**:
```dart
import 'package:convert/convert.dart';

// 编码
final encoded = latin2.encode('Zażółć gęślą jaźń');

// 解码
final decoded = latin2.decode(encoded);
```

### 4. 固定格式日期时间格式化器

**文件位置**: `lib/src/fixed_datetime_formatter.dart`

**功能描述**:
- 使用固定模式字符串格式化和解析 DateTime
- 与 `package:intl` 的 DateFormat 不同，字符数量按字面解释

**支持的格式字符**:
- `Y` - 年份
- `M` - 月份
- `D` - 日期
- `E` - 十年
- `C` - 世纪
- `h` - 小时
- `m` - 分钟
- `s` - 秒
- `S` - 秒的小数部分（最多 6 位，微秒）

**使用场景**:
- 固定格式的日志时间戳
- 特定格式的数据交换
- 性能敏感的日期解析

**API 示例**:
```dart
import 'package:convert/convert.dart';

final formatter = FixedDateTimeFormatter('YYYYMMDDhhmmss');

// 编码
final dateStr = formatter.encode(DateTime(1996, 4, 25, 5, 3, 22));
// 输出: "19960425050322"

// 解码
final date = formatter.decode('19960425050322');
// 结果: DateTime(1996, 4, 25, 5, 3, 22)
```

### 5. 累加器 Sink (Accumulator Sinks)

**文件位置**: 
- `lib/src/accumulator_sink.dart`
- `lib/src/byte_accumulator_sink.dart`
- `lib/src/string_accumulator_sink.dart`

**功能描述**:
- 为分块转换器提供同步访问输出的能力
- 收集所有传递给它的事件

**类型**:
- `AccumulatorSink<T>` - 通用累加器
- `ByteAccumulatorSink` - 字节累加器，输出 `Uint8List`
- `StringAccumulatorSink` - 字符串累加器

**使用场景**:
- 分块数据处理
- 流式转换的中间结果收集
- 测试和调试转换器

**API 示例**:
```dart
import 'package:convert/convert.dart';

final sink = ByteAccumulatorSink();
// 添加数据
sink.add([1, 2, 3]);
sink.add([4, 5, 6]);

// 获取累积的字节
final bytes = sink.bytes; // Uint8List [1, 2, 3, 4, 5, 6]

// 清空
sink.clear();
```

### 6. 身份编解码器 (Identity Codec)

**文件位置**: `lib/src/identity_codec.dart`

**功能描述**:
- 实现 `Codec<T, T>`，不做任何转换
- 输入直接传递到输出

**使用场景**:
- 作为可选 Codec 参数的默认值
- 组合多个编解码器时的占位符
- 与其他 Codec 融合时会消失（返回另一个 Codec）

**API 示例**:
```dart
import 'package:convert/convert.dart';

const identity = IdentityCodec<String>();
final result = identity.encode('hello'); // 'hello'

// 融合特性
final fused = identity.fuse(utf8); // 返回 utf8
```

## 架构设计

### 设计模式

1. **Codec 模式**: 所有编解码器都遵循 Dart 的 `Codec<S, T>` 接口
2. **单例模式**: 使用 `const` 实例（如 `hex`, `percent`）
3. **策略模式**: 不同的编码策略可以互换使用
4. **组合模式**: 通过 `fuse()` 方法组合多个编解码器

### 核心接口

```dart
abstract class Codec<S, T> {
  Encoder<S, T> get encoder;
  Decoder<T, S> get decoder;
  
  T encode(S input);
  S decode(T encoded);
  
  Codec<S, R> fuse<R>(Codec<T, R> other);
}
```

### 分块转换支持

所有编解码器都支持分块转换（chunked conversion），适用于流式数据处理：

```dart
// 示例：分块解码
final decoder = hex.decoder;
final sink = StringBuffer();
final conversionSink = decoder.startChunkedConversion(
  StringConversionSink.fromStringSink(sink)
);

conversionSink.add('ff');
conversionSink.add('fe');
conversionSink.close();
```

## 依赖关系

### 运行时依赖
- `typed_data: ^1.3.0` - 类型化数据支持

### 开发依赖
- `benchmark_harness: ^2.2.0` - 性能基准测试
- `dart_flutter_team_lints: ^3.0.0` - 代码规范
- `test: ^1.17.0` - 单元测试

### SDK 要求
- Dart SDK: ^3.4.0

## 测试覆盖

项目包含完整的测试套件：

- `accumulator_sink_test.dart` - 累加器测试
- `byte_accumulator_sink_test.dart` - 字节累加器测试
- `codepage_test.dart` - 代码页测试
- `fixed_datetime_formatter_test.dart` - 日期格式化器测试
- `hex_test.dart` - 十六进制编解码测试
- `identity_codec_test.dart` - 身份编解码器测试
- `percent_test.dart` - 百分号编码测试
- `string_accumulator_sink_test.dart` - 字符串累加器测试

## 性能优化

项目包含性能基准测试：
- `fixed_datetime_formatter_benchmark.dart` - 日期格式化器性能测试

优化要点：
1. 使用 `Uint8List` 和 `Uint16List` 等类型化数组
2. BMP（基本多文种平面）字符的特殊优化
3. 避免不必要的字符串拼接
4. 分块处理大数据流

## 版本历史亮点

- **3.1.0**: 添加固定模式 DateTime 格式化器
- **3.0.0**: 稳定的空安全版本，添加 CodePage 类
- **2.1.0**: 添加 IdentityCodec
- **1.1.0**: 添加 AccumulatorSink 系列类
- **1.0.0**: 初始版本

## 适用场景

### 适合使用 convert 包的场景

1. **数据编码转换**
   - 需要十六进制、百分号编码等标准编码
   - 处理遗留系统的特殊字符集
   
2. **日期时间处理**
   - 固定格式的日期时间解析（性能优于 intl）
   - 不需要国际化的简单日期格式化

3. **流式数据处理**
   - 需要分块处理大文件
   - 实时数据流转换

4. **编解码器组合**
   - 需要组合多个转换步骤
   - 构建自定义数据处理管道

### 不适合的场景

1. 需要复杂国际化支持 → 使用 `package:intl`
2. 需要 Base64 编码 → 使用 `dart:convert` 内置的 base64
3. 需要 JSON 处理 → 使用 `dart:convert` 内置的 json
4. 需要压缩 → 使用 `dart:io` 的 gzip/zlib

## 为自己项目创建 Package 的建议

基于 convert 包的设计，以下是创建自己 package 的最佳实践：

### 1. 项目结构

```
your_package/
├── lib/
│   ├── your_package.dart          # 主导出文件
│   └── src/                        # 实现细节
│       ├── feature1.dart
│       ├── feature2.dart
│       └── feature1/               # 复杂功能的子模块
│           ├── encoder.dart
│           └── decoder.dart
├── test/                           # 测试文件
│   ├── feature1_test.dart
│   └── feature2_test.dart
├── example/                        # 示例代码
│   └── example.dart
├── benchmark/                      # 性能测试（可选）
│   └── feature_benchmark.dart
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
├── LICENSE
└── AUTHORS                         # 可选
```

### 2. 代码组织原则

**主导出文件** (`lib/your_package.dart`):
```dart
// 只导出公共 API
export 'src/feature1.dart';
export 'src/feature2.dart';

// 隐藏内部实现
export 'src/feature1/encoder.dart' hide internalHelper;
```

**实现文件** (`lib/src/`):
- 所有实现放在 `src/` 目录
- 使用下划线前缀标记私有成员
- 复杂功能拆分为子目录

### 3. API 设计

**提供常量实例**:
```dart
// 方便使用的单例
const myCodec = MyCodec._();

class MyCodec extends Codec<Input, Output> {
  const MyCodec._();
  // ...
}
```

**支持 Codec 接口**:
```dart
class MyCodec extends Codec<S, T> {
  @override
  Encoder<S, T> get encoder => _encoder;
  
  @override
  Decoder<T, S> get decoder => _decoder;
  
  // 支持组合
  @override
  Codec<S, R> fuse<R>(Codec<T, R> other) {
    return super.fuse(other);
  }
}
```

**支持分块转换**:
```dart
class MyDecoder extends Converter<Input, Output> {
  @override
  Output convert(Input input) {
    // 同步转换
  }
  
  @override
  Sink<Input> startChunkedConversion(Sink<Output> sink) {
    // 分块转换支持
    return MyConversionSink(sink);
  }
}
```

### 4. 文档规范

**README.md 应包含**:
- 简洁的项目描述
- 安装说明
- 快速开始示例
- 主要功能列表
- 链接到详细文档

**代码注释**:
```dart
/// 简短的一句话描述。
///
/// 详细的功能说明，可以多段。
///
/// 使用示例：
/// ```dart
/// final result = myFunction('input');
/// ```
///
/// 参数说明、异常说明等。
class MyClass {
  // ...
}
```

### 5. 测试策略

**单元测试**:
- 每个公共 API 都要有测试
- 测试正常情况和边界情况
- 测试错误处理

**测试文件命名**:
```
lib/src/feature.dart → test/feature_test.dart
```

**测试示例**:
```dart
import 'package:test/test.dart';
import 'package:your_package/your_package.dart';

void main() {
  group('Feature', () {
    test('should handle normal case', () {
      expect(feature.process('input'), equals('output'));
    });
    
    test('should throw on invalid input', () {
      expect(() => feature.process(null), throwsArgumentError);
    });
  });
}
```

### 6. 版本管理

**遵循语义化版本**:
- MAJOR: 不兼容的 API 变更
- MINOR: 向后兼容的功能新增
- PATCH: 向后兼容的问题修正

**CHANGELOG.md 格式**:
```markdown
## 1.1.0

- Added new feature X
- Fixed bug in Y
- Deprecated old API Z

## 1.0.0

- Initial stable release
```

### 7. 性能考虑

**使用类型化数据**:
```dart
import 'dart:typed_data';

// 优先使用
Uint8List bytes = Uint8List(100);

// 而不是
List<int> bytes = List.filled(100, 0);
```

**避免不必要的拷贝**:
```dart
// 好的做法
Uint8List.sublistView(original, start, end);

// 避免
original.sublist(start, end); // 会创建新列表
```

### 8. 发布清单

发布前检查：
- [ ] 所有测试通过
- [ ] 文档完整且准确
- [ ] CHANGELOG 已更新
- [ ] 版本号已更新
- [ ] 示例代码可运行
- [ ] 依赖版本合理
- [ ] LICENSE 文件存在
- [ ] README 包含徽章（CI、版本等）

### 9. 持续集成

**GitHub Actions 示例** (`.github/workflows/dart.yaml`):
```yaml
name: Dart CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart analyze
      - run: dart test
```

### 10. 最佳实践总结

1. **保持简单**: 每个包只做一件事，做好它
2. **遵循约定**: 使用 Dart 社区的标准结构和命名
3. **文档优先**: 好的文档比复杂的功能更重要
4. **测试驱动**: 先写测试，再写实现
5. **性能意识**: 但不要过早优化
6. **向后兼容**: 尽量避免破坏性变更
7. **社区友好**: 及时响应 issue 和 PR
8. **持续改进**: 定期更新依赖和改进代码

## 总结

Convert 包是一个设计优秀、文档完善的 Dart 官方包，展示了如何构建一个专业的数据转换工具库。它的设计理念、代码组织和 API 设计都值得在创建自己的 package 时借鉴。

关键要点：
- 清晰的模块划分
- 一致的 API 设计
- 完善的测试覆盖
- 良好的性能优化
- 详细的文档说明

通过学习 convert 包的设计，可以帮助你创建出高质量、易维护、用户友好的 Dart package。
