# AGENTS

本文件面向会在本仓库内工作的代码代理、自动化工具与贡献者，目标是让实现、测试与文档保持一致。

## 项目定位

- 项目名称：Glosc 2FA
- 项目类型：SwiftUI + SwiftData 的本地 Authenticator 应用
- 当前平台：iOS / iPadOS
- 当前阶段：本地 OTP MVP 已可用，后续继续补生态能力

## 当前实现状态

当前代码库已经实现：

- SwiftUI App 生命周期入口与 SwiftData 容器装配
- OTP 账号的新增、编辑、删除与本地持久化
- TOTP / HOTP 生成，支持 SHA1 / SHA256 / SHA512 与 6~8 位验证码
- otpauth 链接导入与二维码扫描导入
- Keychain 共享密钥存储与旧明文密钥迁移
- 生物识别 / 设备密码解锁与基础安全设置
- 主题切换、复制验证码、统一操作反馈
- 简体中文、英文、日文、法文、德文、西班牙文本地化
- 单元测试与基础 UI 测试

当前尚未实现或未完整覆盖：

- iCloud 同步
- Widget / Watch / 更多平台 target
- 完整导出、备份与恢复链路

不要把上面的“未实现”写成已经完成。

## 目录与职责

- `Glosc 2fa/Glosc_2faApp.swift`：应用入口、ModelContainer、全局环境对象装配
- `Glosc 2fa/ContentView.swift`：账号列表页、设置入口、旧密钥迁移、锁屏覆盖层
- `Glosc 2fa/Models/`：OTP 枚举、账号记录、草稿校验、偏好设置、操作反馈状态
- `Glosc 2fa/Services/`：Base32、OTP 生成、otpauth 解析、Keychain、生物识别、安全控制
- `Glosc 2fa/Views/`：账号行、详情、表单、设置、锁屏、二维码扫描
- `Glosc 2fa/*.lproj/Localizable.strings`：界面文案本地化资源
- `Glosc 2faTests/`：单元测试
- `Glosc 2faUITests/`：UI 测试

## 开发约束

- 优先完成 OTP 核心链路，不要过早扩展外设或生态功能
- 不要把业务逻辑继续堆进 `ContentView`
- 新增逻辑优先放到独立 Model / Service / View 辅助类型中
- 优先使用 Apple 原生框架，不要为当前阶段引入不必要依赖
- 修 bug 时做最小改动，不顺手做大重构

## 本地化约束

- 所有新增用户可见文本都必须走本地化，不要直接把中文或英文硬编码进 UI
- 当前项目使用 `L10n.tr` / `L10n.format` 读取 `Localizable.strings`
- 新增文案时，至少同步更新：
  - `zh-Hans.lproj`
  - `en.lproj`
  - `ja.lproj`
  - `fr.lproj`
  - `de.lproj`
  - `es.lproj`
- 枚举标题、错误提示、Toast 文案、按钮标题、Section 标题都算用户可见文本
- 非用户可见常量（如 accessibilityIdentifier、UserDefaults key、内部存储 key）不要本地化
- 改动 UI 文案后，检查 UI 测试是否依赖了特定语言文本；现有 UI 测试会强制使用简体中文启动

## 代码风格

- 遵循现有 Swift 风格：类型名 UpperCamelCase，属性与函数 lowerCamelCase
- SwiftUI View 保持职责单一，`body` 外复杂逻辑拆成私有 helper 或独立类型
- `@Environment` / `@EnvironmentObject` / `@State` 按现有文件布局放在类型顶部
- 持久化实体继续使用 SwiftData `@Model`
- 领域错误继续用 `LocalizedError` 枚举表达，不要返回模糊字符串
- 不要用 `as any`、`@ts-ignore` 之类的规避手段（即使这里主要是 Swift，也同样适用：不要用粗暴方式压错误）

## 测试要求

- OTP 生成逻辑必须优先由单元测试覆盖
- URI 解析必须覆盖正常输入、缺失参数、非法算法、非法位数、非法计数器等情况
- UI 测试只覆盖关键主流程，不要拿 UI 测试替代业务层测试
- 改动用户可见文案或本地化逻辑时，至少确认：
  - 简体中文默认流程可用
  - UI 测试文本定位未被破坏
  - 资源文件包含所有新增 key

## 构建与测试命令

常用命令：

```bash
xcodebuild -project "Glosc 2fa.xcodeproj" -scheme "Glosc 2fa" -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -project "Glosc 2fa.xcodeproj" -scheme "Glosc 2fa" -destination 'platform=iOS Simulator,name=iPhone 16' test
```

运行单个测试可用：

```bash
xcodebuild -project "Glosc 2fa.xcodeproj" -scheme "Glosc 2fa" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:"Glosc 2faTests/Glosc_2faTests/base32DecoderHandlesNormalizedInput" test
```

运行单个 UI 测试可用：

```bash
xcodebuild -project "Glosc 2fa.xcodeproj" -scheme "Glosc 2fa" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:"Glosc 2faUITests/Glosc_2faUITests/testAddAccountFlow" test
```

说明：

- 若本机没有 `iPhone 16` 模拟器，替换为已安装设备
- UI 测试依赖 `UITEST_RESET_STATE` 启动参数重置状态
- 当前 UI 测试还会强制使用简体中文语言环境，避免文案定位漂移

## 文档约束

- `README.md` 负责项目总览、当前状态与路线图
- `docs/development.md` 负责开发流程、模块拆分建议与测试策略
- 若实现状态发生变化，必须同步更新 README 与开发文档
- 文档必须明确区分“已实现”“规划中”“建议方案”

## 平台说明

- 当前 Xcode 工程仍是 iPhone / iPad 设备家族配置
- README 中提到的 macOS 支持仍然属于目标，不应写成已支持
- 若新增 macOS、watchOS 或 Widget Extension，需要同步更新工程结构说明与文档

## 交付标准

- 说明“做了什么”时要能被代码或命令验证
- 说明“计划做什么”时必须明确标注为规划
- 变更尽量小而完整，优先修根因
- 无法验证的内容，必须在交付说明中明确指出
