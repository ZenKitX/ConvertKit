# Package 方案：data_transform

## 项目定位

一个现代化的 Dart 数据转换工具包，专注于常见的数据格式转换和验证场景，填补 `dart:convert` 和 `package:convert` 之间的空白。

## 核心价值

- **实用性优先**: 解决实际开发中的高频痛点
- **类型安全**: 充分利用 Dart 的类型系统
- **性能优化**: 针对移动端和 Web 端优化
- **易于使用**: 简洁的 API，丰富的示例

## 功能模块设计

### 1. 数字格式化模块 (Number Formatting)

**痛点**: Dart 缺少简单易用的数字格式化工具

**功能**:
```dart
// 货币格式化
final currency = CurrencyCodec('CNY', symbol: '¥');
currency.encode(1234.56); // "¥1,234.56"
currency.decode('¥1,234.56'); // 1234.56

// 百分比
final percent = PercentageCodec(decimals: 2);
percent.encode(0.1234); // "12.34%"
percent.decode('12.34%'); // 0.1234

// 文件大小
final fileSize = FileSizeCodec();
fileSize.encode(1536); // "1.5 KB"
fileSize.decode('1.5 KB'); // 1536

// 自定义数字格式
final custom = NumberFormatCodec(
  pattern: '#,##0.00',
  groupSeparator: ',',
  decimalSeparator: '.',
);
```

**使用场景**:
- 电商应用的价格显示
- 数据统计的百分比展示
- 文件管理器的大小显示
- 财务报表

### 2. 颜色转换模块 (Color Conversion)

**痛点**: 在不同颜色格式间转换很繁琐

**功能**:
```dart
// Hex 颜色
final hexCodec = HexColorCodec();
hexCodec.encode(Color(0xFFFF5733)); // "#FF5733"
hexCodec.decode('#FF5733'); // Color(0xFFFF5733)

// RGB/RGBA
final rgbCodec = RgbColorCodec();
rgbCodec.encode(Color(0xFFFF5733)); // "rgb(255, 87, 51)"
rgbCodec.decode('rgb(255, 87, 51)'); // Color

// HSL/HSLA
final hslCodec = HslColorCodec();
hslCodec.encode(color); // "hsl(9, 100%, 60%)"

// 颜色空间转换
final converter = ColorSpaceConverter();
converter.rgbToHsl(255, 87, 51); // HSL values
converter.hslToRgb(9, 100, 60); // RGB values
```

**使用场景**:
- UI 主题系统
- CSS 样式生成
- 图像处理应用
- 设计工具

### 3. 时间段格式化模块 (Duration Formatting)

**痛点**: Duration 的 toString() 不够人性化

**功能**:
```dart
// 人性化时间段
final humanCodec = HumanDurationCodec(locale: 'zh_CN');
humanCodec.encode(Duration(hours: 2, minutes: 30)); // "2小时30分钟"
humanCodec.encode(Duration(seconds: 45)); // "45秒"

// 紧凑格式
final compactCodec = CompactDurationCodec();
compactCodec.encode(Duration(hours: 1, minutes: 23, seconds: 45)); // "1:23:45"

// ISO 8601 格式
final isoCodec = IsoDurationCodec();
isoCodec.encode(Duration(hours: 2, minutes: 30)); // "PT2H30M"
isoCodec.decode('PT2H30M'); // Duration(hours: 2, minutes: 30)

// 相对时间
final relativeCodec = RelativeTimeCodec(locale: 'zh_CN');
relativeCodec.encode(DateTime.now().subtract(Duration(minutes: 5))); // "5分钟前"
relativeCodec.encode(DateTime.now().add(Duration(hours: 2))); // "2小时后"
```

**使用场景**:
- 社交应用的时间显示
- 视频播放器的时长显示
- 任务管理的倒计时
- 日志系统

### 4. 数据验证模块 (Data Validation)

**痛点**: 需要在转换时进行数据验证

**功能**:
```dart
// 验证编解码器
final emailCodec = ValidatedCodec<String>(
  validator: (email) => email.contains('@'),
  errorMessage: '无效的邮箱地址',
);

// 范围验证
final ageCodec = RangeCodec<int>(min: 0, max: 150);
ageCodec.encode(25); // 25
ageCodec.encode(200); // 抛出 RangeError

// 正则验证
final phoneCodec = RegexCodec(
  pattern: r'^1[3-9]\d{9}$',
  errorMessage: '无效的手机号',
);

// 组合验证
final userCodec = CompositeCodec({
  'email': emailCodec,
  'age': ageCodec,
  'phone': phoneCodec,
});
```

**使用场景**:
- 表单验证
- API 数据校验
- 配置文件解析
- 数据导入

### 5. 单位转换模块 (Unit Conversion)

**痛点**: 常见单位转换需要手动计算

**功能**:
```dart
// 长度单位
final lengthConverter = LengthConverter();
lengthConverter.convert(1, from: Unit.meter, to: Unit.kilometer); // 0.001
lengthConverter.convert(1, from: Unit.mile, to: Unit.kilometer); // 1.609

// 温度单位
final tempConverter = TemperatureConverter();
tempConverter.celsiusToFahrenheit(0); // 32
tempConverter.fahrenheitToCelsius(32); // 0

// 重量单位
final weightConverter = WeightConverter();
weightConverter.convert(1, from: Unit.kilogram, to: Unit.pound); // 2.205

// 时间单位
final timeConverter = TimeConverter();
timeConverter.convert(1, from: Unit.hour, to: Unit.second); // 3600
```

**使用场景**:
- 国际化应用
- 科学计算
- 健康健身应用
- 天气应用

### 6. 数据脱敏模块 (Data Masking)

**痛点**: 敏感数据需要脱敏显示

**功能**:
```dart
// 手机号脱敏
final phoneMask = PhoneMaskCodec();
phoneMask.encode('13812345678'); // "138****5678"

// 身份证脱敏
final idCardMask = IdCardMaskCodec();
idCardMask.encode('110101199001011234'); // "110101********1234"

// 邮箱脱敏
final emailMask = EmailMaskCodec();
emailMask.encode('user@example.com'); // "u***@example.com"

// 银行卡脱敏
final cardMask = BankCardMaskCodec();
cardMask.encode('6222021234567890'); // "6222 **** **** 7890"

// 自定义脱敏
final customMask = CustomMaskCodec(
  keepStart: 3,
  keepEnd: 4,
  maskChar: '*',
);
```

**使用场景**:
- 用户信息展示
- 日志记录
- 数据导出
- 隐私保护

## 项目结构

```
data_transform/
├── lib/
│   ├── data_transform.dart              # 主导出
│   └── src/
│       ├── number/                       # 数字格式化
│       │   ├── currency_codec.dart
│       │   ├── percentage_codec.dart
│       │   ├── file_size_codec.dart
│       │   └── number_format_codec.dart
│       ├── color/                        # 颜色转换
│       │   ├── hex_color_codec.dart
│       │   ├── rgb_color_codec.dart
│       │   ├── hsl_color_codec.dart
│       │   └── color_space_converter.dart
│       ├── duration/                     # 时间段格式化
│       │   ├── human_duration_codec.dart
│       │   ├── compact_duration_codec.dart
│       │   ├── iso_duration_codec.dart
│       │   └── relative_time_codec.dart
│       ├── validation/                   # 数据验证
│       │   ├── validated_codec.dart
│       │   ├── range_codec.dart
│       │   ├── regex_codec.dart
│       │   └── composite_codec.dart
│       ├── unit/                         # 单位转换
│       │   ├── length_converter.dart
│       │   ├── temperature_converter.dart
│       │   ├── weight_converter.dart
│       │   └── time_converter.dart
│       ├── masking/                      # 数据脱敏
│       │   ├── phone_mask_codec.dart
│       │   ├── email_mask_codec.dart
│       │   ├── id_card_mask_codec.dart
│       │   └── custom_mask_codec.dart
│       └── common/                       # 公共工具
│           ├── base_codec.dart
│           └── utils.dart
├── test/                                 # 测试
├── example/                              # 示例
├── benchmark/                            # 性能测试
└── docs/                                 # 文档
```

## 技术特性

### 1. 统一的 Codec 接口

```dart
abstract class DataCodec<S, T> extends Codec<S, T> {
  const DataCodec();
  
  @override
  DataEncoder<S, T> get encoder;
  
  @override
  DataDecoder<T, S> get decoder;
  
  // 支持可选参数的编码
  T encodeWithOptions(S input, {Map<String, dynamic>? options});
  
  // 支持可选参数的解码
  S decodeWithOptions(T encoded, {Map<String, dynamic>? options});
  
  // 验证输入
  bool validate(S input);
  
  // 安全转换（返回 null 而不是抛异常）
  T? tryEncode(S input);
  S? tryDecode(T encoded);
}
```

### 2. 链式调用支持

```dart
// 组合多个转换
final pipeline = utf8
  .fuse(base64)
  .fuse(customCodec);

// 使用管道
final result = DataPipeline()
  .add(trimCodec)
  .add(lowercaseCodec)
  .add(emailCodec)
  .process('  USER@EXAMPLE.COM  '); // "user@example.com"
```

### 3. 国际化支持

```dart
// 支持多语言
final codec = HumanDurationCodec(locale: 'zh_CN');
final codec2 = HumanDurationCodec(locale: 'en_US');

// 支持自定义本地化
final customLocale = LocaleData(
  hour: '时',
  minute: '分',
  second: '秒',
);
```

### 4. 扩展性设计

```dart
// 用户可以轻松扩展
class MyCustomCodec extends DataCodec<Input, Output> {
  @override
  Output encode(Input input) {
    // 自定义实现
  }
  
  @override
  Input decode(Output encoded) {
    // 自定义实现
  }
}
```

## 依赖规划

```yaml
dependencies:
  # 最小化依赖
  intl: ^0.19.0  # 国际化支持（可选）

dev_dependencies:
  test: ^1.24.0
  benchmark_harness: ^2.2.0
  lints: ^3.0.0
```

## 开发路线图

### Phase 1: MVP (v0.1.0)
- [ ] 数字格式化模块（货币、百分比、文件大小）
- [ ] 时间段格式化模块（人性化、紧凑格式）
- [ ] 基础测试覆盖
- [ ] 示例代码
- [ ] README 文档

### Phase 2: 核心功能 (v0.2.0)
- [ ] 颜色转换模块
- [ ] 数据验证模块
- [ ] 完善测试（80%+ 覆盖率）
- [ ] API 文档

### Phase 3: 扩展功能 (v0.3.0)
- [ ] 单位转换模块
- [ ] 数据脱敏模块
- [ ] 性能优化
- [ ] 基准测试

### Phase 4: 稳定版本 (v1.0.0)
- [ ] 完整的测试覆盖（90%+）
- [ ] 完善的文档
- [ ] 示例应用
- [ ] CI/CD 配置
- [ ] 发布到 pub.dev

## 竞品分析

| 功能 | data_transform | intl | convert | 其他 |
|------|----------------|------|---------|------|
| 数字格式化 | ✅ 简单易用 | ✅ 功能强大但复杂 | ❌ | - |
| 颜色转换 | ✅ | ❌ | ❌ | 需要多个包 |
| 时间段格式化 | ✅ | ⚠️ 部分支持 | ❌ | - |
| 数据验证 | ✅ | ❌ | ❌ | validators |
| 单位转换 | ✅ | ❌ | ❌ | units_converter |
| 数据脱敏 | ✅ | ❌ | ❌ | 需自己实现 |
| 统一 API | ✅ | ❌ | ✅ | - |
| 类型安全 | ✅ | ⚠️ | ✅ | - |

## 差异化优势

1. **一站式解决方案**: 整合常见的数据转换需求
2. **现代化 API**: 充分利用 Dart 3+ 特性
3. **实用性优先**: 专注于实际开发中的高频场景
4. **性能优化**: 针对移动端和 Web 端优化
5. **易于扩展**: 清晰的架构，方便用户自定义

## 示例应用场景

### 场景 1: 电商应用

```dart
import 'package:data_transform/data_transform.dart';

// 价格显示
final priceCodec = CurrencyCodec('CNY', symbol: '¥');
final price = priceCodec.encode(1234.56); // "¥1,234.56"

// 折扣显示
final discountCodec = PercentageCodec(decimals: 0);
final discount = discountCodec.encode(0.15); // "15%"

// 文件大小
final sizeCodec = FileSizeCodec();
final size = sizeCodec.encode(1536000); // "1.5 MB"
```

### 场景 2: 社交应用

```dart
// 相对时间
final relativeCodec = RelativeTimeCodec(locale: 'zh_CN');
final time = relativeCodec.encode(
  DateTime.now().subtract(Duration(minutes: 5))
); // "5分钟前"

// 手机号脱敏
final phoneMask = PhoneMaskCodec();
final masked = phoneMask.encode('13812345678'); // "138****5678"
```

### 场景 3: 数据可视化

```dart
// 颜色转换
final hexCodec = HexColorCodec();
final color = hexCodec.decode('#FF5733');

// 百分比格式化
final percentCodec = PercentageCodec(decimals: 1);
final percent = percentCodec.encode(0.856); // "85.6%"
```

## 成功指标

### 技术指标
- 测试覆盖率 > 90%
- 所有公共 API 都有文档
- 性能基准测试通过
- 零运行时依赖（intl 可选）

### 社区指标
- pub.dev 评分 > 130
- GitHub stars > 100
- 至少 5 个实际项目使用
- 活跃的 issue 响应（< 48 小时）

## 风险与挑战

### 技术风险
- **国际化复杂性**: 不同语言的格式差异大
  - 缓解: 先支持中英文，逐步扩展
  
- **性能问题**: 频繁的字符串操作可能影响性能
  - 缓解: 使用 StringBuffer，缓存常用结果

### 市场风险
- **竞品压力**: intl 包功能强大
  - 差异化: 更简单的 API，更实用的功能
  
- **用户接受度**: 新包需要时间推广
  - 策略: 完善文档，提供丰富示例

## 下一步行动

1. **立即开始**:
   - 创建项目结构
   - 实现货币格式化（最常用）
   - 编写基础测试

2. **第一周**:
   - 完成数字格式化模块
   - 完成时间段格式化模块
   - 编写 README 和示例

3. **第二周**:
   - 发布 v0.1.0 到 pub.dev
   - 收集反馈
   - 开始实现颜色转换模块

4. **持续迭代**:
   - 根据用户反馈调整优先级
   - 逐步完善功能
   - 建立社区

## 总结

`data_transform` 定位为一个实用、易用、高性能的数据转换工具包，填补现有 Dart 生态的空白。通过专注于实际开发中的高频场景，提供统一、类型安全的 API，帮助开发者更高效地处理数据转换需求。

项目采用渐进式开发策略，先实现核心功能快速验证市场需求，再根据反馈逐步完善。通过清晰的架构设计和完善的文档，确保项目的可维护性和可扩展性。
