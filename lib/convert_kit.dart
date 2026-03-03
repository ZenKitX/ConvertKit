/// 数据转换工具包。
///
/// 提供多种编解码器和格式化工具，用于在不同数据表示之间进行转换。
///
/// ## 主要功能
///
/// - 十六进制编解码
/// - 百分号编码（URL 编码）
/// - 代码页支持（ISO-8859 系列）
/// - 日期时间格式化
/// - 累加器 Sink
/// - 身份编解码器
///
/// ## 使用示例
///
/// ```dart
/// import 'package:convert_kit/convert_kit.dart';
///
/// // 十六进制编解码
/// final hexString = hex.encode([255, 254, 253]);
/// print(hexString); // 'fffefd'
///
/// // 百分号编码
/// final encoded = percent.encode([65, 66, 67, 32, 49, 50, 51]);
/// print(encoded); // 'ABC%20123'
/// ```
library convert_kit;

// 导出将在后续 commit 中逐步添加
// export 'src/accumulator_sink.dart';
// export 'src/byte_accumulator_sink.dart';
// export 'src/string_accumulator_sink.dart';
// export 'src/hex.dart';
// export 'src/percent.dart';
// export 'src/codepage.dart';
// export 'src/fixed_datetime_formatter.dart';
// export 'src/identity_codec.dart';
