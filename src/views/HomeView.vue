<template>
  <div class="shell py-16 sm:py-20 lg:py-24">
    <section class="grid gap-10 lg:grid-cols-[minmax(0,1.15fr)_minmax(320px,0.85fr)] lg:items-center">
      <div>
        <div class="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-2 text-xs uppercase tracking-[0.22em] text-text-secondary">
          Apple 平台双重验证工具
        </div>
        <h1 class="mt-6 max-w-4xl font-display text-5xl font-semibold tracking-tight text-text-primary sm:text-6xl lg:text-7xl">
          用更安静的界面，管理更重要的验证码。
        </h1>
        <p class="mt-6 max-w-2xl text-lg leading-8 text-text-secondary sm:text-xl">
          Glosc Authenticator 为 iPhone 与 iPad 设计，支持 TOTP、HOTP、二维码导入、Keychain 安全存储与设备身份验证，让双重验证回到简单可靠。
        </p>

        <div class="mt-8 flex flex-col gap-4 sm:flex-row">
          <RouterLink to="/download" class="button-primary">前往下载</RouterLink>
          <RouterLink to="/support" class="button-secondary">技术支持与协议</RouterLink>
        </div>

        <div class="mt-10 grid gap-5 text-sm text-text-secondary sm:grid-cols-3">
          <div>
            <p class="font-display text-3xl font-semibold text-text-primary">TOTP / HOTP</p>
            <p class="mt-2">完整支持主流 OTP 协议和多种哈希算法。</p>
          </div>
          <div>
            <p class="font-display text-3xl font-semibold text-text-primary">Keychain</p>
            <p class="mt-2">共享密钥优先安全存储，兼顾旧数据迁移。</p>
          </div>
          <div>
            <p class="font-display text-3xl font-semibold text-text-primary">Apple 体验</p>
            <p class="mt-2">围绕 iOS / iPadOS 的交互与视觉细节打磨。</p>
          </div>
        </div>
      </div>

      <div class="glass-panel relative overflow-hidden p-6 sm:p-8">
        <div class="absolute inset-x-10 top-0 h-px bg-gradient-to-r from-transparent via-white/30 to-transparent" />
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm uppercase tracking-[0.22em] text-text-muted">实时预览</p>
            <p class="mt-2 font-display text-2xl font-semibold text-text-primary">Glosc Authenticator</p>
          </div>
          <span class="rounded-full border border-emerald-400/20 bg-emerald-400/10 px-3 py-1 text-xs text-emerald-200">
            Secure
          </span>
        </div>

        <div class="mt-8 space-y-4">
          <div class="rounded-2xl border border-white/8 bg-black/20 p-4">
            <div class="flex items-start justify-between gap-4">
              <div>
                <p class="text-sm text-text-muted">Glosc Cloud</p>
                <p class="mt-1 font-display text-xl font-medium text-text-primary">482 091</p>
              </div>
              <div class="text-right text-xs text-text-muted">
                <p>TOTP</p>
                <p>23s</p>
              </div>
            </div>
          </div>

          <div class="rounded-2xl border border-white/8 bg-white/4 p-4">
            <div class="flex items-start justify-between gap-4">
              <div>
                <p class="text-sm text-text-muted">Apple ID</p>
                <p class="mt-1 font-display text-xl font-medium text-text-primary">617 204</p>
              </div>
              <div class="text-right text-xs text-text-muted">
                <p>TOTP</p>
                <p>12s</p>
              </div>
            </div>
          </div>

          <div class="rounded-2xl border border-white/8 bg-white/3 p-4">
            <div class="flex items-start justify-between gap-4">
              <div>
                <p class="text-sm text-text-muted">SSH Console</p>
                <p class="mt-1 font-display text-xl font-medium text-text-primary">Counter +1</p>
              </div>
              <div class="text-right text-xs text-text-muted">
                <p>HOTP</p>
                <p>Manual</p>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-8 grid gap-4 sm:grid-cols-2">
          <div class="rounded-2xl border border-white/8 bg-white/4 p-4">
            <p class="text-sm text-text-muted">导入方式</p>
            <p class="mt-2 text-text-primary">扫码导入 / otpauth 链接</p>
          </div>
          <div class="rounded-2xl border border-white/8 bg-white/4 p-4">
            <p class="text-sm text-text-muted">解锁方式</p>
            <p class="mt-2 text-text-primary">Face ID / Touch ID</p>
          </div>
        </div>
      </div>
    </section>

    <section class="mt-20 grid gap-6 lg:grid-cols-3">
      <article class="glass-panel p-7">
        <p class="text-sm uppercase tracking-[0.2em] text-text-muted">轻量而完整</p>
        <h2 class="mt-4 font-display text-2xl font-semibold text-text-primary">覆盖 OTP 的核心主流程</h2>
        <p class="mt-4 section-copy">
          新增、编辑、删除、本地持久化、二维码扫描导入、验证码复制与倒计时展示都已经落地，适合个人与小团队使用。
        </p>
      </article>

      <article class="glass-panel p-7">
        <p class="text-sm uppercase tracking-[0.2em] text-text-muted">严格校验</p>
        <h2 class="mt-4 font-display text-2xl font-semibold text-text-primary">通过 RFC 标准测试向量</h2>
        <p class="mt-4 section-copy">
          HOTP 与 TOTP 生成逻辑已用 RFC 4226 / RFC 6238 标准测试向量验证，确保每一个验证码都符合预期。
        </p>
      </article>

      <article class="glass-panel p-7">
        <p class="text-sm uppercase tracking-[0.2em] text-text-muted">面向后续扩展</p>
        <h2 class="mt-4 font-display text-2xl font-semibold text-text-primary">为同步与组件能力预留空间</h2>
        <p class="mt-4 section-copy">
          当前优先聚焦 OTP 核心体验，后续将逐步扩展 iCloud 同步、小组件、Watch 与更多平台形态。
        </p>
      </article>
    </section>
  </div>
</template>

<script setup lang="ts">
import { RouterLink } from 'vue-router'
</script>
