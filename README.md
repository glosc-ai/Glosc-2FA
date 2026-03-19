# Glosc 2FA

Glosc 2FA 是一款面向 Apple 平台的双重验证工具，目标是提供简洁、安全、可靠的验证码管理体验。

当前仓库仍处于项目初始化阶段，现有代码是基于 SwiftUI 和 SwiftData 的工程骨架，尚未实现完整的 2FA 业务能力。本文档将产品目标、当前状态与后续开发方向分开说明，避免文档和代码状态不一致。

## 项目目标

- 支持通过扫码导入和导出账号
- 支持 TOTP 和 HOTP 协议
- 支持自定义账号名称、图标、颜色
- 支持 Touch ID 和 Face ID 解锁
- 支持本地持久化账号数据
- 支持 iCloud 同步账号数据
- 支持 Apple Watch 显示验证码
- 支持小组件显示验证码
- 支持暗黑模式
- 遵循 Apple Human Interface Guidelines
- 开源、免费、无广告

## 当前状态

当前代码库已完成的内容：

- 建立了 SwiftUI 应用入口
- 集成了 SwiftData 持久化容器
- 提供了基础列表页与新增、删除示例数据的能力
- 生成了单元测试与 UI 测试 target 骨架

当前尚未实现的核心能力：

- OTP 密钥解析与验证码生成
- 二维码扫描与 otpauth 链接导入
- 账号模型设计与安全存储
- 生物识别解锁
- iCloud 同步
- 小组件、Watch 支持、多平台适配

## 技术栈

- Swift
- SwiftUI
- SwiftData
- Xcode 工程管理
- Apple Testing / XCTest

## 项目结构

```text
.
├── Glosc 2fa/                # 应用主 target
├── Glosc 2faTests/           # 单元测试
├── Glosc 2faUITests/         # UI 测试
├── Glosc 2fa.xcodeproj/      # Xcode 工程
├── AGENTS.md                 # 仓库内协作与代码代理说明
├── README.md                 # 项目总览
└── docs/
	└── development.md        # 开发文档
```

## 本地开发

### 环境要求

- macOS
- Xcode 26 或更高版本
- iOS Simulator

说明：当前工程配置为 iPhone 与 iPad 设备家族，README 中的 macOS 支持仍属于目标范围，尚未体现在现有工程 target 中。

### 打开工程

1. 使用 Xcode 打开 Glosc 2fa.xcodeproj
2. 选择方案 Glosc 2fa
3. 选择一个 iOS 模拟器后运行

### 命令行构建示例

```bash
xcodebuild -project "Glosc 2fa.xcodeproj" -scheme "Glosc 2fa" -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### 命令行测试示例

```bash
xcodebuild -project "Glosc 2fa.xcodeproj" -scheme "Glosc 2fa" -destination 'platform=iOS Simulator,name=iPhone 16' test
```

如本机没有对应模拟器，请替换为已安装的设备名称。

## 开发原则

- 文档必须明确区分“已实现”和“规划中”
- 优先完成 OTP 核心能力，再扩展同步、穿戴设备与小组件能力
- 保持 SwiftUI 视图职责单一，避免将业务逻辑堆积在单个 View 中
- 数据模型演进时同步更新测试与开发文档

## 推荐迭代顺序

1. 设计账号领域模型与 OTP 生成逻辑
2. 增加 otpauth URI 解析与导入能力
3. 引入更贴近业务的数据结构，替换当前示例 Item 模型
4. 补齐单元测试，覆盖时间步进、位数、算法和异常输入
5. 接入扫码、生物识别与安全存储
6. 再扩展 iCloud、Widget、Watch 与跨平台能力

## 相关文档

- 开发文档：docs/development.md
- 代理协作说明：AGENTS.md



