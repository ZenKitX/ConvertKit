# ConvertKit 性能基准测试

本目录包含 ConvertKit 各模块的性能基准测试。

## 运行基准测试

### 运行所有基准测试

```bash
dart run benchmark/hex_benchmark.dart
dart run benchmark/percent_benchmark.dart
```

### 运行单个基准测试

```bash
# 十六进制编解码基准测试
dart run benchmark/hex_benchmark.dart

# 百分号编解码基准测试
dart run benchmark/percent_benchmark.dart
```

## 基准测试说明

### hex_benchmark.dart

测试十六进制编解码器的性能，包括：

- 编码性能：字节数组转十六进制字符串
- 解码性能：十六进制字符串转字节数组
- 往返转换：编码后再解码

测试数据规模：

- 小数据：100 字节
- 中等数据：10KB
- 大数据：1MB

### percent_benchmark.dart

测试百分号编解码器的性能，包括：

- 编码性能：字节数组转百分号编码字符串
- 解码性能：百分号编码字符串转字节数组
- 往返转换：编码后再解码

测试数据规模：

- 小数据：12 字节（普通文本）
- 中等数据：1KB
- 大数据：100KB
- 特殊字符：包含 Unicode 和特殊符号

## 性能指标

每个基准测试输出以下指标：

- 总时间：完成所有迭代的总时间（毫秒）
- 平均时间：单次操作的平均时间（毫秒）
- 吞吐量：每秒处理的数据量（MB/s）

## CI/CD 集成

基准测试已集成到 CI/CD 流程中，每次推送到 main 或 develop 分支时自动运行。

查看 `.github/workflows/dart.yml` 了解详情。

## 添加新的基准测试

创建新的基准测试文件时，请遵循以下规范：

1. 文件命名：`<module>_benchmark.dart`
2. 包含版权声明
3. 测试多种数据规模
4. 输出清晰的性能指标
5. 在 CI/CD 配置中添加运行步骤

示例结构：

```dart
import 'package:convert_kit/convert_kit.dart';

void main() {
  print('=== 模块性能基准测试 ===\n');
  
  // 准备测试数据
  final testData = ...;
  
  // 运行基准测试
  _benchmark('测试名称', testData, iterations);
}

void _benchmark(String name, dynamic data, int iterations) {
  final stopwatch = Stopwatch()..start();
  
  for (var i = 0; i < iterations; i++) {
    // 执行操作
  }
  
  stopwatch.stop();
  // 输出结果
}
```
