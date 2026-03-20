<template>
  <div class="shell py-16 sm:py-20 lg:py-24">
    <section class="grid gap-12 lg:grid-cols-[minmax(0,1.05fr)_minmax(360px,0.95fr)] lg:items-center">
      <div>
        <div class="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/4 px-4 py-2 text-xs uppercase tracking-[0.22em] text-text-secondary">
          iPhone / iPad Authenticator
        </div>
        <h1 class="mt-6 max-w-4xl font-display text-5xl font-semibold tracking-tight text-text-primary sm:text-6xl lg:text-7xl">
          Glosc 2FA
          <br>
          Authenticator
        </h1>
        <p class="mt-6 max-w-2xl text-lg leading-8 text-text-secondary sm:text-xl">
          Glosc 2FA 为 Apple 平台设计。支持 TOTP、HOTP、二维码导入、Keychain 安全存储与设备身份验证。
        </p>

        <div class="mt-8 flex flex-col gap-4 sm:flex-row">
          <RouterLink to="/download" class="button-primary">前往下载</RouterLink>
          <RouterLink to="/support" class="button-secondary">技术支持与协议</RouterLink>
        </div>

        <div class="mt-10 grid gap-5 text-sm text-text-secondary sm:grid-cols-3">
          <div>
            <p class="font-display text-3xl font-semibold text-text-primary">纯黑界面</p>
            <p class="mt-2">延续截图中的安静视觉，不让界面喧宾夺主。</p>
          </div>
          <div>
            <p class="font-display text-3xl font-semibold text-text-primary">圆角卡片</p>
            <p class="mt-2">重点信息集中在单张卡片里，读码路径更直接。</p>
          </div>
          <div>
            <p class="font-display text-3xl font-semibold text-text-primary">Apple 体验</p>
            <p class="mt-2">围绕 iOS / iPadOS 的字体、留白和交互节奏构建。</p>
          </div>
        </div>
      </div>

      <div class="relative mx-auto w-full max-w-[420px]  lg:mr-0">
        <div class="absolute left-1/2 top-1/2 h-72 w-72 -translate-x-1/2 -translate-y-1/2 rounded-full bg-white/6 blur-3xl" />
        <div class="relative">
          <div class="relative overflow-hidden rounded-[2.5rem] border border-white/8 bg-black p-5 shadow-[0_30px_100px_rgba(0,0,0,0.55)]">
            <div class="flex items-center justify-between px-2 pb-6 text-white">
              <span class="text-xl font-semibold">12:00</span>
              <div class="flex items-center gap-2 text-sm text-white/70">
                <span>●●●</span>
                <span>◜◝</span>
                <span>▭</span>
              </div>
            </div>

            <div class="flex items-center justify-between">
              <div class="flex h-12 w-12 items-center justify-center rounded-full border border-white/12 bg-white/8 text-xl text-white">⚙</div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full border border-white/12 bg-white/8 text-3xl leading-none text-white">+</div>
            </div>

            <h3 class="mt-8 font-display text-4xl font-semibold tracking-tight text-white">Glosc 2FA</h3>

            <div class="mt-6 rounded-[2rem] bg-[#1d1d1f] px-5 py-5 text-white">
              <div class="flex items-start justify-between gap-4">
                <div>
                  <p class="text-xl font-semibold tracking-tight">alice@example.com</p>
                  <p class="mt-1 text-lg text-white/45">Example</p>
                </div>
                <div class="text-right">
                  <p class="text-2xl font-semibold tracking-[0.06em]">282760</p>
                  <p class="mt-1 text-lg text-white/55">HOTP</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="mt-20 grid gap-6 lg:grid-cols-3">
      <article class="glass-panel p-7">
        <p class="text-sm uppercase tracking-[0.2em] text-text-muted">界面语言</p>
        <h2 class="mt-4 font-display text-2xl font-semibold text-text-primary">直接复用应用的视觉语气</h2>
        <p class="mt-4 section-copy">
          截图里的纯黑背景、超大标题、弱化装饰和圆角卡片，是产品最强的辨识度，官网应该服务于它，而不是盖过它。
        </p>
      </article>

      <article class="glass-panel p-7">
        <p class="text-sm uppercase tracking-[0.2em] text-text-muted">核心能力</p>
        <h2 class="mt-4 font-display text-2xl font-semibold text-text-primary">TOTP、HOTP 与安全存储已经到位</h2>
        <p class="mt-4 section-copy">
          支持二维码导入、otpauth 链接解析、验证码复制、倒计时显示，以及 Keychain 与设备身份验证保护。
        </p>
      </article>

      <article class="glass-panel p-7">
        <p class="text-sm uppercase tracking-[0.2em] text-text-muted">后续方向</p>
        <h2 class="mt-4 font-display text-2xl font-semibold text-text-primary">先把验证码体验做好，再扩展同步能力</h2>
        <p class="mt-4 section-copy">
          当前优先聚焦 OTP 核心使用场景，后续再逐步扩展 iCloud 同步、小组件、Watch 与更多平台支持。
        </p>
      </article>
    </section>
  </div>
</template>

<script setup lang="ts">
import { RouterLink } from 'vue-router'
</script>
