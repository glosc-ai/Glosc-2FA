<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'

const navigation = [
  { to: '/', label: '首页' },
  { to: '/download', label: '下载' },
  { to: '/support', label: '技术支持 / 协议条款' },
]

const appStorePlaceholder = 'https://apps.apple.com/app/id0000000000'
</script>

<template>
  <div class="relative overflow-hidden">
    <div class="pointer-events-none absolute inset-x-0 top-[-16rem] h-[32rem] bg-[radial-gradient(circle,_rgba(146,182,255,0.22),_transparent_58%)] blur-3xl" />

    <header class="sticky top-0 z-20 border-b border-white/8 bg-slate-950/65 backdrop-blur-xl">
      <div class="shell flex items-center justify-between gap-4 py-4">
        <RouterLink to="/" class="flex items-center gap-3">
          <div class="flex h-11 w-11 items-center justify-center rounded-2xl border border-white/10 bg-white/6 text-lg font-semibold text-white shadow-[0_12px_30px_rgba(0,0,0,0.25)]">
            G
          </div>
          <div>
            <p class="font-display text-sm uppercase tracking-[0.24em] text-text-muted">Glosc</p>
            <p class="font-display text-lg font-semibold tracking-tight text-text-primary">Authenticator</p>
          </div>
        </RouterLink>

        <nav class="hidden items-center gap-2 md:flex">
          <RouterLink
            v-for="item in navigation"
            :key="item.to"
            :to="item.to"
            class="nav-link"
            active-class="nav-link-active"
            exact-active-class="nav-link-active"
          >
            {{ item.label }}
          </RouterLink>
        </nav>

        <a :href="appStorePlaceholder" class="button-secondary hidden md:inline-flex" target="_blank" rel="noreferrer">
          App Store
        </a>
      </div>

      <div class="shell flex gap-2 overflow-x-auto pb-4 md:hidden">
        <RouterLink
          v-for="item in navigation"
          :key="`${item.to}-mobile`"
          :to="item.to"
          class="nav-link whitespace-nowrap"
          active-class="nav-link-active"
          exact-active-class="nav-link-active"
        >
          {{ item.label }}
        </RouterLink>
      </div>
    </header>

    <main>
      <RouterView />
    </main>

    <footer class="border-t border-white/8 bg-black/30 py-10">
      <div class="shell flex flex-col gap-6 text-sm text-text-secondary md:flex-row md:items-end md:justify-between">
        <div>
          <p class="font-display text-base font-medium text-text-primary">Glosc Authenticator</p>
          <p class="mt-2 max-w-xl leading-7 text-text-secondary">
            面向 Apple 平台的双重验证工具，强调简洁、安全与可靠的验证码管理体验。
          </p>
        </div>

        <div class="space-y-1 text-left md:text-right">
          <p>© 2026 Glosc AI. 保留所有权利。</p>
          <p>沪ICP备2026003781号-1</p>
          <p>沪公网安备31011202022083号</p>
        </div>
      </div>
    </footer>
  </div>
</template>
