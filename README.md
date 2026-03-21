# Glosc Authenticator

Glosc Authenticator 是一款面向 Apple 平台的双重验证(Authenticator)工具，目标是提供简洁、安全、可靠的验证码管理体验。

当前仓库已经完成一个可运行的 iOS / iPadOS MVP：支持本地管理 OTP 账号、生成验证码，并覆盖最小主流程测试。本文档将产品目标、当前状态与后续开发方向分开说明，避免文档和代码状态不一致。

## 项目目标

- 支持通过扫码导入和导出账号
- 支持 TOTP 和 HOTP 协议
- 支持自定义账号名称、图标、颜色
- 支持 Touch ID 和 Face ID 解锁
- 支持本地持久化账号数据
- 支持应用内主题与语言切换
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
- 用真实 OTP 账号模型替换了模板 Item
- 支持手动新增、编辑、删除 OTP 账号
- 支持通过 otpauth 链接导入 TOTP / HOTP 账号
- 支持通过二维码扫描导入 otpauth 账号
- 支持 SHA1、SHA256、SHA512 算法和 6 到 8 位验证码
- HOTP 与 TOTP 生成逻辑已通过 RFC 4226 / RFC 6238 标准测试向量校验
- 支持显示 TOTP 倒计时与 HOTP 计数器推进
- 支持 Keychain 安全存储共享密钥，并兼容旧数据迁移
- 支持设备身份验证解锁与开启、关闭保护前的身份校验，并提供主题、语言切换与基础安全设置
- 支持详情页点按或长按验证码复制、列表长按快速复制，以及复制、导入、保存、删除等统一操作提示
- 支持简体中文、英文、日文、法文、德文、西班牙文、意大利文、韩文、巴西葡萄牙文界面
- 补齐了 Base32、HOTP、TOTP、otpauth 解析的单元测试
- 增加了 Keychain 读写单元测试
- 增加了基础 UI 测试，覆盖新增账号、设置入口、删除与 HOTP 主流程

当前尚未实现的核心能力：

- iCloud 同步
- 小组件、Watch 支持、多平台适配
- 更完整的导出能力与账号定制化展示

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
│   ├── Models/               # OTP 模型与草稿校验
│   ├── Services/             # Base32、验证码生成、otpauth 解析、安全与扫描
│   └── Views/                # 列表、详情、表单、设置、锁屏
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
- 共享密钥应优先保存在 Keychain 等安全存储中，持久化模型只保留展示与关联信息
- 新增用户可见文案时，需要同步更新 Localizable.strings 的各语言条目

## 推荐迭代顺序

1. 继续补充 UI 测试，覆盖设置、编辑、删除、HOTP 递增与扫码回退路径
2. 增强导出、备份与恢复能力
3. 设计并实现 iCloud 同步的数据模型与冲突处理
4. 再扩展 Widget、Watch 与更多平台 target

## 相关文档

- 开发文档：docs/development.md
- 代理协作说明：AGENTS.md


