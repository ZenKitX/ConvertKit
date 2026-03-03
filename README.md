# ConvertKit

[![Pub Version](https://img.shields.io/pub/v/convert_kit)](https://pub.dev/packages/convert_kit)
[![License](https://img.shields.io/badge/license-BSD--3-blue.svg)](LICENSE)

数据转换工具包，提供多种编解码器和格式化工具。

## 特性

- 🔢 **十六进制编解码** - 字节数组与十六进制字符串相互转换
- 🔗 **百分号编码** - URL 编码/解码，符合 RFC 3986 规范
- 🔄 **身份编解码器** - 用于编解码器组合的占位符
- 📦 **累加器 Sink** - 为分块转换提供同步访问

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  convert_kit: ^0.1.0
```

然后运行：

```bash
dart pub get
```

## 快速开始

```dart
import 'package:convert_kit/convert_kit.dart';

void main() {
  // 十六进制编解码
  final bytes = [255, 254, 253];
  final hexString = hex.encode(bytes);
  print(hexString); // 'fffefd'
  
  final decoded = hex.decode('fffefd');
  print(decoded); // [255, 254, 253]
  
  // 百分号编码
  final encoded = percent.encode([65, 66, 67, 32, 49, 50, 51]);
  print(encoded); // 'ABC%20123'
}
```

## 文档

详细文档请访问 [API 文档](https://pub.dev/documentation/convert_kit/latest/)。

## 示例

更多示例请查看 [example](example/) 目录。

## 性能基准测试

ConvertKit 提供了完整的性能基准测试套件，用于评估各模块的性能表现。

运行基准测试：

```bash
# 十六进制编解码
dart run benchmark/hex_benchmark.dart

# 百分号编解码
dart run benchmark/percent_benchmark.dart
```

详细信息请查看 [benchmark](benchmark/) 目录。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

本项目采用 BSD-3-Clause 许可证。详见 [LICENSE](LICENSE) 文件。

## 致谢

本项目受 Dart 官方 [convert](https://pub.dev/packages/convert) 包启发。

参考仓库：[dart-lang/convert](https://github.com/dart-lang/convert)
