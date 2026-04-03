# Glosc 2FA 开发文档

## 1. 文档目的

本文档面向项目开发者，说明当前工程结构、推荐迭代路径、模块拆分方向与测试策略。它不是产品宣传文档，而是为了帮助后续开发尽快把工程骨架演进成真正可用的 2FA 应用。

## 2. 当前工程现状

当前仓库已经完成 OTP 主流程的第一版实现，主要包含以下内容：

- SwiftUI App 入口
- SwiftData 容器初始化
- OTP 账号 SwiftData 模型与草稿校验
- Base32 解码、TOTP/HOTP 验证码生成、otpauth URI 解析
- Keychain 共享密钥存储与旧数据迁移
- Firebase Google / Apple 认证、可选登录与云同步
- 设备身份验证锁定状态控制、主题与语言切换，以及设置持久化
- 多语言界面资源（简体中文、英文、日文、法文、德文、西班牙文、意大利文、韩文、巴西葡萄牙文）
- 账号列表、详情、手动录入、otpauth 导入、二维码扫描导入、编辑和删除
- 列表长按复制验证码、详情页点按或长按验证码复制，并提供统一的成功/失败操作提示
- 覆盖标准测试向量的单元测试、Keychain 测试与基础 UI 测试

这意味着当前代码已经具备本地 Authenticator 的可用核心链路，并补上了扫码导入、基础安全能力与 Firebase 云同步；后续仍需继续完善导出、Widget 与 Watch 等扩展能力。

## 3. 现有文件职责

### 应用主 target

- Glosc 2fa/Glosc_2faApp.swift
  负责应用入口、SwiftData 容器注入、偏好对象与安全状态对象装配，并根据应用偏好切换主题与界面语言。
- Glosc 2fa/ContentView.swift
  负责账号列表页、导航、设置入口、旧密钥迁移与锁屏覆盖层调度。
- Glosc 2fa/Models/
  包含 OTPAlgorithm、OTPKind、OTPAccountRecord、OTPAccountDraft、AppPreferences 与输入校验。
- Glosc 2fa/Services/
  包含 Base32Decoder、OTPCodeGenerator、OTPAuthURIParser、KeychainSecretStore、BiometricAuthService、AppSecurityController，以及 Firebase 云同步与客户端加密服务。
- Glosc 2fa/Views/
  包含账号列表行、详情页、录入与导入表单、设置页、锁屏视图与二维码扫描视图，以及验证码复制交互。

### 测试 target

- Glosc 2faTests/
  当前已覆盖 OTP 算法、URI 解析、非法输入校验与 Keychain 读写，后续可继续补模型迁移与安全状态测试。
- Glosc 2faUITests/
  当前已覆盖新增账号主流程，后续适合补充设置、导入、编辑、删除、HOTP 行为等关键路径。

## 4. 建议的业务拆分

建议先围绕 OTP 核心实现进行拆分，而不是先做 UI 扩张。

### 4.1 领域模型

当前已引入下列核心对象：

- OTPAccount
  当前以 OTPAccountRecord 和 OTPAccountDraft 组合落地，分别承担持久化和输入校验职责。
- OTPKind
  已用于区分 TOTP 与 HOTP。
- OTPAlgorithm
  已支持 SHA1、SHA256、SHA512。
- OTPCodeGenerator
  已负责根据时间戳或计数器生成验证码，并提供 TOTP 倒计时信息；当前实现已通过 RFC 4226 与 RFC 6238 的标准测试向量。

### 4.2 数据持久化

当前实现采用了相对轻量的分工：

- OTPAccountRecord 负责 SwiftData 存储结构
- OTPAccountDraft 负责表单输入、规范化和校验
- OTPCodeGenerator 与 OTPAuthURIParser 负责独立业务逻辑

这套拆分已经足够支撑当前 MVP。后续若接入导入导出、同步或安全存储，可以继续引入更显式的 Repository / Mapper 层。

### 4.3 功能模块

当前已经实现以下模块：

1. 账号列表
2. 新建或导入账号
3. 账号详情与验证码展示
4. 编辑账号信息

仍未实现：

1. 导出与备份恢复
2. iCloud 同步能力
3. Widget、Watch 与更多平台扩展

在 SwiftUI 层面，建议每个功能模块至少拆成：

- View
- ViewModel 或状态容器
- Service 或 Use Case

是否显式命名为 ViewModel 可以按团队习惯决定，但状态与业务逻辑不应继续集中在单个视图文件中。

## 5. OTP 实现建议

### 5.1 TOTP

当前已具备：

- 基于共享密钥生成一次性验证码
- 支持配置位数
- 支持配置时间步长
- 支持基础算法配置
- 正确处理剩余有效时间显示

### 5.2 HOTP

HOTP 需要额外维护计数器。实现时应注意：

- 计数器更新策略必须明确
- 与 UI 展示行为保持一致
- 持久化写入应避免重复递增或状态丢失

当前实现方式：

- 列表和详情页会显示当前 HOTP 验证码
- 详情页提供“标记当前 HOTP 已使用”按钮来显式推进计数器
- 计数器递增后会立即保存到 SwiftData

### 5.3 otpauth URI

当前已经实现 URI 解析层，用于支撑手动粘贴导入，已覆盖：

- scheme 校验
- label 解析
- secret 解析
- issuer 解析
- digits、period、counter、algorithm 参数解析
- 异常输入兜底和错误提示

## 6. 安全与存储建议

由于本项目目标涉及认证信息，数据安全应尽早进入设计，而不是后补。

建议原则：

- 明文密钥不要在调试日志中输出
- 设备身份验证解锁应与敏感信息展示行为联动
- 评估是否将密钥类数据放入更合适的安全存储方案
- 若使用 iCloud 同步，先定义冲突解决策略，再落地数据同步

当前仓库尚未实现这些能力，因此新增功能时要优先补足最小安全边界。
当前已落地的最小安全边界包括：

- 共享密钥写入 Keychain
- 旧明文密钥迁移到 Keychain
- 可选的设备身份验证解锁
- 列表页验证码隐藏与详情页密钥展示开关
- Firebase Google / Apple 认证接入
- 上传到 Firestore 前对账号载荷进行客户端 AES-GCM 加密
- 使用独立同步口令与每用户 salt 派生同步密钥，并将派生结果缓存到 Keychain

当前交互层已补充的便捷能力包括：

- 应用内主题切换，可在跟随系统、浅色和深色之间切换
- 多语言界面，可随系统语言或在设置中手动切换简体中文、英文、日文、法文、德文、西班牙文、意大利文、韩文、巴西葡萄牙文
- 开启或关闭身份验证保护前，先触发 Face ID、Touch ID 或设备密码验证
- 详情页点按或长按验证码卡片快速复制，并区分复制成功与复制失败提示
- 列表页长按账号行快速复制当前验证码，并区分复制成功与复制失败提示
- 导入、保存、删除等关键操作提供统一提示
- 可选登录、退出登录、同步状态展示与手动触发同步
- Google 登录使用 Firebase `google.com` OAuth Provider，当前工程通过 Firebase App ID 编码后的自定义 URL scheme 回收授权结果
- Apple 登录使用 AuthenticationServices 原生流程 + nonce，并通过 Firebase `OAuthProvider.appleCredential(...)` 完成身份认证
- 首次开启云同步时要求用户设置独立同步口令；后续在新设备上登录同一身份后，需要输入同步口令才能解密云端数据

Firebase 同步当前采用的文档结构：

```text
users/{uid}
  - email
  - kdfSalt
  - keyVerifier
  - providerIDs
  - createdAt
  - updatedAt

users/{uid}/accounts/{accountId}
  - ciphertext
  - createdAt
  - updatedAt
  - schemaVersion
```

说明：

- 数据库中不直接保存 OTP 明文字段，账号详情会先序列化后在客户端加密
- 当前冲突处理采用 updatedAt 较新者覆盖；首次登录时会把本地缺失的账号推送到云端
- 若用户已保留 Firebase 登录态但本地丢失派生密钥，需要重新输入同步口令以恢复解密能力

## 7. UI 与交互建议

README 中已明确目标是符合 Apple 平台设计规范，因此在 UI 上建议遵循以下原则：

- 列表页优先突出账号名、发行方和当前验证码
- 倒计时必须清晰可感知，但不应产生过度动画干扰
- 导入流程优先保证成功率与错误反馈，而不是堆叠复杂入口
- 颜色和图标定制属于增强能力，应建立在核心流程稳定之后

## 8. 测试策略

### 8.1 必须优先补齐的单元测试

- TOTP 生成结果与标准测试向量比对
- HOTP 计数器行为测试
- Base32 密钥解析测试
- otpauth URI 解析测试
- 非法输入与边界条件测试

当前已完成其中的前四类，并补充了非法密钥输入校验测试。

### 8.2 UI 测试建议覆盖的流程

- 首次启动进入主界面
- 新增或导入账号
- 查看验证码
- 编辑账号
- 删除账号

当前已落地：

- 首次启动
- 手动新增账号
- 设置页入口可达性
- 删除账号
- 详情页 HOTP 递增

建议下一步补上：

- 设置页主题与显示偏好的行为验证
- 扫码不可用时的回退提示

### 8.3 不建议的做法

- 用 UI 测试覆盖底层算法正确性
- 在缺少单元测试时直接堆叠功能页面
- 让测试依赖真实网络或外部服务
- 让单元测试依赖真实 Firebase 服务

## 9. 推荐迭代计划

### 里程碑 1：替换模板骨架

已完成。

### 里程碑 2：打通最小主流程

已完成。

### 里程碑 3：导入与安全

- 支持 otpauth 导入
- 接入扫码
- 接入设备身份验证解锁

当前状态：已完成。

### 里程碑 4：生态能力扩展

- iCloud 同步
- Widget
- Apple Watch
- 更完整的平台支持

## 10. 协作文档约定

- README 只做总览，不承载实现细节
- 任何功能落地后，应同步更新 README 与本开发文档
- 如果某个能力只是规划中，必须明确写成“目标”或“计划”
- 如果工程 target 发生变化，例如新增 macOS 或 watchOS，必须同步更新文档
- 新增用户可见文本时，必须同步更新各语言 Localizable.strings，避免只更新单一语言

## 11. 当前最值得优先做的事

如果继续推进开发，建议从下面三项开始：

1. 扩充 UI 测试，覆盖设置、删除和 HOTP 计数器行为
2. 设计导出、备份与恢复格式
3. 规划 iCloud 同步前的数据冲突与密钥同步边界

## 12. Firebase 接入注意事项

本仓库已完成客户端接入，但要让功能真正可用，还需要配套 Firebase 控制台配置：

1. 首次进入 Authentication 页面，确保项目已完成 Authentication 初始化；未初始化时常见报错是 `CONFIGURATION_NOT_FOUND`
2. 启用 Authentication 的 Google Provider
3. 启用 Authentication 的 Apple Provider，并同步填写 Apple Team ID、Service ID、Key ID 与私钥
4. 创建 Firestore 数据库并部署用户隔离规则
5. 确认 GoogleService-Info.plist 与目标 Firebase 项目一致
6. 确认工程 Info.plist 中注册的 OAuth callback scheme 与当前 Firebase App ID 一致
7. 确认 Apple Developer 中的 App ID 已启用 Sign in with Apple capability
8. 若要做联调，优先使用测试项目而不是生产项目
