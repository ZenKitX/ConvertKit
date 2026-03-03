# ConvertKit 开发计划

## 项目定位

基于 `package:convert` 的学习和复现，保留核心功能的同时融入个人风格和现代化改进。

## 项目命名

**ConvertKit** - 既致敬原项目，又体现工具包的定位

## 开发原则

### 提交规范

**Commit Message 格式**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type 类型**:
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档变更
- `style`: 代码格式（不影响代码运行）
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

**示例**:
```
feat(hex): 实现十六进制编解码器

- 添加 HexCodec 类实现 RFC 4648 Base16 规范
- 实现 HexEncoder 支持字节数组到十六进制字符串转换
- 实现 HexDecoder 支持十六进制字符串到字节数组转换
- 添加完整的文档注释
- 包含基础单元测试

Closes #1
```

### 代码规范

1. **每次提交原则**:
   - 单一职责：一次提交只做一件事
   - 完整性：包含代码、测试、文档
   - 可运行：提交后代码必须能通过测试
   - 适量修改：核心功能单次提交控制在 200-300 行

2. **文档要求**:
   - 所有公共 API 必须有文档注释
   - 使用 `///` 三斜线注释
   - 包含功能描述、参数说明、返回值、使用示例
   - 复杂逻辑添加行内注释

3. **测试要求**:
   - 每个功能必须有对应测试
   - 测试覆盖正常情况和边界情况
   - 测试文件与源文件同步提交

## 开发路线图

### Phase 0: 项目初始化

**Commit 1: 初始化项目结构**
```
chore: 初始化 ConvertKit 项目

- 创建基础目录结构
- 配置 pubspec.yaml
- 添加 README.md
- 配置 analysis_options.yaml
- 添加 LICENSE 和 AUTHORS
```

**文件清单**:
- `pubspec.yaml`
- `README.md`
- `CHANGELOG.md`
- `LICENSE`
- `AUTHORS`
- `analysis_options.yaml`
- `.gitignore`

---

### Phase 1: 基础设施

**Commit 2: 添加工具类和常量**
```
feat(utils): 添加基础工具类

- 添加字符编码常量 (charcodes.dart)
- 添加通用工具函数 (utils.dart)
- 包含完整文档注释
```

**文件**:
- `lib/src/charcodes.dart`
- `lib/src/utils.dart`

---

### Phase 2: 累加器模块

**Commit 3: 实现通用累加器**
```
feat(accumulator): 实现 AccumulatorSink

- 添加 AccumulatorSink<T> 泛型类
- 支持事件收集和访问
- 支持清空和关闭操作
- 添加完整文档和示例
- 包含单元测试
```

**文件**:
- `lib/src/accumulator_sink.dart`
- `test/accumulator_sink_test.dart`

**Commit 4: 实现字节累加器**
```
feat(accumulator): 实现 ByteAccumulatorSink

- 继承 AccumulatorSink 实现字节专用累加器
- 返回 Uint8List 类型
- 优化字节数组合并性能
- 添加文档和测试
```

**文件**:
- `lib/src/byte_accumulator_sink.dart`
- `test/byte_accumulator_sink_test.dart`

**Commit 5: 实现字符串累加器**
```
feat(accumulator): 实现 StringAccumulatorSink

- 继承 AccumulatorSink 实现字符串专用累加器
- 使用 StringBuffer 优化性能
- 添加文档和测试
```

**文件**:
- `lib/src/string_accumulator_sink.dart`
- `test/string_accumulator_sink_test.dart`

---

### Phase 3: 十六进制编解码

**Commit 6: 实现十六进制编码器**
```
feat(hex): 实现 HexEncoder

- 实现字节数组到十六进制字符串的转换
- 支持大小写选项（个人风格）
- 支持分块转换
- 添加完整文档和测试
```

**文件**:
- `lib/src/hex/encoder.dart`
- `test/hex_encoder_test.dart`

**Commit 7: 实现十六进制解码器**
```
feat(hex): 实现 HexDecoder

- 实现十六进制字符串到字节数组的转换
- 支持大小写混合输入
- 支持分块转换
- 添加错误处理和文档
- 包含测试
```

**文件**:
- `lib/src/hex/decoder.dart`
- `test/hex_decoder_test.dart`

**Commit 8: 实现十六进制编解码器**
```
feat(hex): 实现 HexCodec 完整功能

- 组合 HexEncoder 和 HexDecoder
- 提供统一的 hex 常量实例
- 添加便捷方法
- 完善文档和集成测试
```

**文件**:
- `lib/src/hex.dart`
- `test/hex_test.dart`

---

### Phase 4: 百分号编码

**Commit 9: 实现百分号编码器**
```
feat(percent): 实现 PercentEncoder

- 实现 RFC 3986 百分号编码
- 支持自定义保留字符集（个人风格）
- 支持分块转换
- 添加文档和测试
```

**文件**:
- `lib/src/percent/encoder.dart`
- `test/percent_encoder_test.dart`

**Commit 10: 实现百分号解码器**
```
feat(percent): 实现 PercentDecoder

- 实现百分号解码功能
- 支持 + 号处理选项
- 添加错误处理
- 包含文档和测试
```

**文件**:
- `lib/src/percent/decoder.dart`
- `test/percent_decoder_test.dart`

**Commit 11: 实现百分号编解码器**
```
feat(percent): 实现 PercentCodec 完整功能

- 组合编码器和解码器
- 提供 percent 常量实例
- 添加集成测试
```

**文件**:
- `lib/src/percent.dart`
- `test/percent_test.dart`

---

### Phase 5: 身份编解码器

**Commit 12: 实现身份编解码器**
```
feat(identity): 实现 IdentityCodec

- 实现不做任何转换的编解码器
- 支持泛型类型
- 实现 fuse 方法优化
- 添加文档和测试
```

**文件**:
- `lib/src/identity_codec.dart`
- `test/identity_codec_test.dart`

---

### Phase 6: 代码页编码

**Commit 13: 实现代码页基础结构**
```
feat(codepage): 实现 CodePage 基础类

- 定义 CodePage 抽象类
- 实现字符映射机制
- 添加 BMP 优化版本
- 包含文档
```

**文件**:
- `lib/src/codepage.dart` (部分)

**Commit 14: 添加 ISO-8859 编码支持**
```
feat(codepage): 添加 ISO-8859 系列编码

- 实现 Latin-2 到 Latin-10
- 实现西里尔、阿拉伯、希腊、希伯来等编码
- 添加字符映射表
- 包含测试
```

**文件**:
- `lib/src/codepage.dart` (完整)
- `test/codepage_test.dart`

---

### Phase 7: 日期时间格式化器

**Commit 15: 实现日期时间格式化器**
```
feat(datetime): 实现 FixedDateTimeFormatter

- 支持固定模式的日期时间格式化
- 实现编码和解码功能
- 支持 UTC 和本地时区
- 添加完整文档和测试
```

**文件**:
- `lib/src/fixed_datetime_formatter.dart`
- `test/fixed_datetime_formatter_test.dart`

---

### Phase 8: 主导出和示例

**Commit 16: 配置主导出文件**
```
feat: 配置主导出文件

- 创建 lib/convert_kit.dart
- 导出所有公共 API
- 隐藏内部实现
```

**文件**:
- `lib/convert_kit.dart`

**Commit 17: 添加示例代码**
```
docs: 添加使用示例

- 创建 example/example.dart
- 展示各个模块的使用方法
- 添加注释说明
```

**文件**:
- `example/example.dart`

**Commit 18: 完善项目文档**
```
docs: 完善项目文档

- 更新 README.md 添加详细说明
- 更新 CHANGELOG.md
- 添加 API 文档链接
```

**文件**:
- `README.md`
- `CHANGELOG.md`

---

### Phase 9: 个人风格增强（可选）

**Commit 19: 添加扩展方法**
```
feat(extensions): 添加便捷扩展方法

- 为 List<int> 添加 toHex() 扩展
- 为 String 添加 fromHex() 扩展
- 为 String 添加 percentEncode/Decode 扩展
- 添加文档和测试
```

**文件**:
- `lib/src/extensions.dart`
- `test/extensions_test.dart`

**Commit 20: 添加构建器模式**
```
feat(builder): 添加编解码器构建器

- 实现 CodecBuilder 支持链式配置
- 支持自定义选项
- 添加文档和示例
```

**文件**:
- `lib/src/codec_builder.dart`
- `test/codec_builder_test.dart`

---

## 个人风格体现

### 1. 命名风格
- 项目名：`convert_kit` (更现代化)
- 类名保持一致，但添加更多便捷方法

### 2. API 增强
```dart
// 原版
hex.encode([255, 254, 253]);

// 增强版（保留原版，额外提供）
[255, 254, 253].toHex(); // 扩展方法
HexCodec.withOptions(uppercase: true).encode([255, 254, 253]);
```

### 3. 错误处理
```dart
// 提供 try* 系列方法
final result = hex.tryDecode('invalid'); // 返回 null 而不是抛异常
```

### 4. 文档风格
```dart
/// 十六进制编解码器。
///
/// 将字节数组与十六进制字符串相互转换，遵循 RFC 4648 Base16 规范。
///
/// ## 使用示例
///
/// ```dart
/// // 编码
/// final encoded = hex.encode([255, 254, 253]);
/// print(encoded); // 'fffefd'
///
/// // 解码
/// final decoded = hex.decode('fffefd');
/// print(decoded); // [255, 254, 253]
/// ```
///
/// ## 性能说明
///
/// 编码和解码操作的时间复杂度均为 O(n)，其中 n 为输入长度。
///
/// 参考: [RFC 4648 Section 8](https://tools.ietf.org/html/rfc4648#section-8)
class HexCodec extends Codec<List<int>, String> {
  // ...
}
```

### 5. 测试风格
```dart
group('HexCodec', () {
  group('编码', () {
    test('应该正确编码空数组', () {
      expect(hex.encode([]), equals(''));
    });

    test('应该正确编码单字节', () {
      expect(hex.encode([255]), equals('ff'));
    });

    test('应该正确编码多字节', () {
      expect(hex.encode([255, 254, 253]), equals('fffefd'));
    });
  });

  group('解码', () {
    test('应该正确解码空字符串', () {
      expect(hex.decode(''), equals([]));
    });

    test('应该支持大小写混合', () {
      expect(hex.decode('FfFeFd'), equals([255, 254, 253]));
    });

    test('应该在输入无效时抛出异常', () {
      expect(() => hex.decode('xyz'), throwsFormatException);
    });
  });
});
```

## 开发工作流

### 每个功能的开发流程

1. **创建分支**
   ```bash
   git checkout -b feat/hex-codec
   ```

2. **编写代码**
   - 先写接口和文档注释
   - 再写实现
   - 最后写测试

3. **运行测试**
   ```bash
   dart test
   dart analyze
   dart format .
   ```

4. **提交代码**
   ```bash
   git add .
   git commit -m "feat(hex): 实现十六进制编解码器"
   ```

5. **推送并创建 PR**（如果使用 PR 流程）
   ```bash
   git push origin feat/hex-codec
   ```

## 质量检查清单

每次提交前检查：

- [ ] 代码通过 `dart analyze`
- [ ] 代码通过 `dart format`
- [ ] 所有测试通过 `dart test`
- [ ] 公共 API 有文档注释
- [ ] 文档注释包含使用示例
- [ ] 复杂逻辑有行内注释
- [ ] 测试覆盖正常和边界情况
- [ ] Commit message 符合规范
- [ ] 单次提交修改量适中（< 300 行核心代码）

## 项目配置文件

### pubspec.yaml
```yaml
name: convert_kit
description: 数据转换工具包，提供编解码器和格式化工具
version: 0.1.0
repository: https://github.com/yourusername/convert_kit

environment:
  sdk: ^3.4.0

dependencies:
  typed_data: ^1.3.0

dev_dependencies:
  test: ^1.24.0
  lints: ^3.0.0
```

### analysis_options.yaml
```yaml
include: package:lints/recommended.yaml

linter:
  rules:
    - always_declare_return_types
    - always_put_required_named_parameters_first
    - avoid_print
    - prefer_single_quotes
    - require_trailing_commas
    - sort_constructors_first
    - sort_unnamed_constructors_first
```

## 时间估算

- Phase 0: 0.5 天
- Phase 1: 0.5 天
- Phase 2: 1 天（3 个 commit）
- Phase 3: 1.5 天（3 个 commit）
- Phase 4: 1.5 天（3 个 commit）
- Phase 5: 0.5 天
- Phase 6: 1.5 天（2 个 commit）
- Phase 7: 1 天
- Phase 8: 0.5 天（3 个 commit）
- Phase 9: 1 天（可选）

**总计**: 约 8-10 天（不含个人风格增强）

## 下一步

准备好开始了吗？我们可以：

1. **立即开始 Phase 0**: 初始化项目结构
2. **先看看某个模块的详细实现**: 比如先看 HexCodec 的完整实现
3. **调整开发计划**: 如果有其他想法

你想从哪里开始？
