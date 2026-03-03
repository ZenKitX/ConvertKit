# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-01-XX

### Added
- 十六进制编解码器（HexCodec, HexEncoder, HexDecoder）
- 百分号编解码器（PercentCodec, PercentEncoder, PercentDecoder）
- 身份编解码器（IdentityCodec）
- 累加器 Sink（AccumulatorSink, ByteAccumulatorSink, StringAccumulatorSink）
- 基础工具类和字符常量
- 完整的测试覆盖（243 个测试用例）
- 详细的中文文档和示例

### Features
- 符合 RFC 3986 规范的百分号编码
- 高效的十六进制转换（使用位运算优化）
- 支持分块转换和流式处理
- 完整的错误处理和边界检查
- 泛型身份编解码器支持
