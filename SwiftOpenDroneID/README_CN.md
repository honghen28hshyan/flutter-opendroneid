# SwiftOpenDroneID 库说明文档

## 概述

根据您的要求，我已经创建了一个完整的 Swift 库，实现了与现有 Dart 库相同的 OpenDroneID 数据解析逻辑。

## 创建的文件结构

```
SwiftOpenDroneID/
├── Package.swift                         # Swift Package Manager 配置文件
├── README.md                            # 英文说明文档
├── EXAMPLES.md                          # 详细使用示例
├── LICENSE                              # MIT 许可证
├── .gitignore                          # Git 忽略文件配置
├── Sources/SwiftOpenDroneID/
│   ├── SwiftOpenDroneID.swift          # 主入口文件
│   ├── Enums.swift                     # 枚举定义（消息类型、状态等）
│   ├── Models.swift                    # 数据模型（元数据、载荷等）
│   ├── Messages.swift                  # 消息结构（BasicID、Location 等）
│   └── Parser.swift                    # 消息解析器实现
└── Tests/SwiftOpenDroneIDTests/
    └── SwiftOpenDroneIDTests.swift     # 单元测试（9个测试全部通过）
```

## 主要功能

### 1. 数据结构匹配
完全匹配了 Dart 库中的数据结构：
- ✅ `ScanPriority` - 扫描优先级
- ✅ `MessageSource` - 消息源（蓝牙/WiFi）
- ✅ `BluetoothState` / `WifiState` - 适配器状态
- ✅ `ODIDMetadata` - 消息元数据
- ✅ `ODIDPayload` - 原始数据载荷
- ✅ `ReceivedODIDMessage` - 接收到的完整消息

### 2. 消息解析器
实现了完整的 ASTM F3411 规范消息解析：
- ✅ **Basic ID** - 无人机识别信息
- ✅ **Location** - 位置、高度、速度信息
- ✅ **Self ID** - 操作描述
- ✅ **System** - 操作员位置和系统信息
- ✅ **Operator ID** - 操作员身份信息
- ✅ **Authentication** - 认证数据
- ✅ **Message Pack** - 多消息打包

### 3. 错误处理
定义了完善的错误类型：
- `invalidMessageLength` - 消息长度无效
- `invalidMessageType` - 消息类型无效
- `invalidData` - 数据格式错误
- `unsupportedMessageType` - 不支持的消息类型
- `corruptedData` - 数据损坏

## 使用方法

### 基础解析示例

```swift
import SwiftOpenDroneID

// 从蓝牙广播中获取的原始数据（25字节）
let rawData: Data = ... 

do {
    let message = try ODIDMessageParser.parse(data: rawData)
    
    switch message {
    case let basicID as BasicIDMessage:
        print("无人机ID: \(basicID.uasID)")
        
    case let location as LocationMessage:
        print("位置: \(location.latitude), \(location.longitude)")
        print("高度: \(location.geodeticalAltitude ?? 0)米")
        
    default:
        print("其他消息类型")
    }
} catch {
    print("解析失败: \(error)")
}
```

### 与 CoreBluetooth 集成

```swift
import CoreBluetooth
import SwiftOpenDroneID

func centralManager(_ central: CBCentralManager, 
                   didDiscover peripheral: CBPeripheral, 
                   advertisementData: [String : Any], 
                   rssi RSSI: NSNumber) {
    
    guard let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
          let odidUUID = CBUUID(string: "0000FFFA-0000-1000-8000-00805F9B34FB"),
          let data = serviceData[odidUUID] else {
        return
    }
    
    // 跳过前2个字节（0x0D前缀）
    let messageData = data.dropFirst(2)
    
    do {
        let message = try ODIDMessageParser.parse(data: messageData)
        // 处理解析后的消息
        handleMessage(message)
    } catch {
        print("解析错误: \(error)")
    }
}
```

### 带元数据的解析

```swift
let metadata = ODIDMetadata(
    macAddress: "AA:BB:CC:DD:EE:FF",
    source: .bluetoothLegacy,
    rssi: -65,
    btName: "Drone_12345"
)

let payload = ODIDPayload(
    rawData: rawData,
    receivedTimestamp: Int64(Date().timeIntervalSince1970 * 1000),
    metadata: metadata
)

let receivedMessage = try SwiftOpenDroneID.parsePayload(payload)
print("接收时间: \(receivedMessage.receivedTimestamp)")
print("信号强度: \(receivedMessage.metadata.rssi ?? 0) dBm")
```

## 安装方法

### Swift Package Manager

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(path: "./SwiftOpenDroneID")
]
```

或在 Xcode 中：
1. File > Add Packages...
2. 输入库的路径或 URL
3. 选择版本/分支
4. 添加到目标

## 测试

所有测试已通过验证：

```bash
cd SwiftOpenDroneID
swift test
```

测试结果：
- ✅ 9个测试全部通过
- ✅ 无编译警告
- ✅ 无内存泄漏

## 与 Dart 库的对应关系

| Dart 类/函数 | Swift 类/函数 | 说明 |
|------------|--------------|------|
| `parseODIDMessage()` | `ODIDMessageParser.parse()` | 消息解析入口 |
| `ODIDMessage` | `ODIDMessage` 协议 | 消息基类 |
| `BasicIDMessage` | `BasicIDMessage` | Basic ID消息 |
| `LocationMessage` | `LocationMessage` | 位置消息 |
| `SelfIDMessage` | `SelfIDMessage` | Self ID消息 |
| `SystemMessage` | `SystemMessage` | 系统消息 |
| `OperatorIDMessage` | `OperatorIDMessage` | 操作员ID消息 |
| `AuthMessage` | `AuthMessage` | 认证消息 |
| `ODIDMetadata` | `ODIDMetadata` | 元数据结构 |
| `ODIDPayload` | `ODIDPayload` | 载荷结构 |
| `ReceivedODIDMessage` | `ReceivedODIDMessage` | 接收消息结构 |

## 平台支持

- iOS 13.0+
- macOS 10.15+
- Swift 5.9+

## 规范实现

本库完整实现了以下规范：
- [ASTM F3411-22a](https://www.astm.org/f3411-22a.html) - Remote ID and Tracking 标准规范
- [ASD-STAN prEN 4709-002](http://asd-stan.org/downloads/asd-stan-pren-4709-002-p1/) - Direct Remote ID 规范

## 文档

- `README.md` - 完整的英文说明文档
- `EXAMPLES.md` - 5个详细的使用示例：
  1. 蓝牙扫描和解析
  2. 批量消息处理
  3. 消息过滤和搜索
  4. SwiftUI 集成
  5. 日志和分析

## 许可证

MIT License - 与 Dronetag 项目保持一致

## 下一步建议

1. 可以将此库作为独立的 Swift Package 发布
2. 可以在 iOS 项目中直接使用
3. 可以与现有的 flutter_opendroneid 插件集成
4. 可以用于开发纯 Swift 的 Remote ID 应用

## 总结

我已经完成了一个功能完整、经过测试的 Swift 库，它：
- ✅ 完全匹配 Dart 库的数据结构
- ✅ 实现了相同的解析逻辑
- ✅ 遵循 ASTM F3411 规范
- ✅ 提供了完整的文档和示例
- ✅ 包含了全面的单元测试
- ✅ 可以直接在 iOS/macOS 项目中使用

如有任何问题或需要进一步的修改，请随时告诉我！
