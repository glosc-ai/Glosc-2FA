<script setup lang="ts">
import { RouterLink } from 'vue-router'

const supportEmail = 'xm@aoe.top'

const terms = [
  {
    title: '使用说明',
    content:
      'Glosc 2FA 用于在 Apple 平台本地管理 OTP 账号并生成动态验证码。请确认导入账号来源可信，并妥善保管设备访问权限。',
  },
  {
    title: '数据与安全',
    content:
      '应用优先使用本地存储与 Keychain 保护共享密钥。若设备被越狱、遭受恶意软件攻击或被未授权访问，仍可能存在数据泄露风险。',
  },
  {
    title: '服务状态',
    content:
      '官网与应用仍在持续迭代中。功能、兼容性与下载方式可能根据审核、系统更新或产品规划调整。',
  },
]
</script>

<template>
  <div class="shell py-16 sm:py-20 lg:py-24">
    <section class="mx-auto max-w-3xl text-center">
      <p class="text-sm uppercase tracking-[0.24em] text-text-muted">Support</p>
      <h1 class="mt-4 font-display text-4xl font-semibold tracking-tight text-text-primary sm:text-5xl">
        技术支持与协议条款
      </h1>
      <p class="mt-6 text-lg leading-8 text-text-secondary sm:text-xl">
        如遇到导入失败、验证码异常、数据保护或下载问题，可通过下方邮箱联系。页面同时提供当前版本的简要条款说明。
      </p>
    </section>

    <section class="mx-auto mt-12 max-w-4xl space-y-6">
      <article class="glass-panel p-8 sm:p-10">
        <p class="text-sm uppercase tracking-[0.2em] text-text-muted">Contact</p>
        <div class="mt-4 flex flex-col gap-6 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h2 class="font-display text-3xl font-semibold text-text-primary">技术支持</h2>
            <p class="mt-3 max-w-2xl text-base leading-7 text-text-secondary">
              邮件支持适用于下载、导入、账号管理、验证码显示异常等问题反馈。
            </p>
          </div>
          <a
            :href="`mailto:${supportEmail}`"
            class="inline-flex rounded-full border border-white/10 bg-white/4 px-5 py-3 font-display text-base text-text-primary transition hover:bg-white/8"
          >
            {{ supportEmail }}
          </a>
        </div>

        <div class="mt-8 rounded-2xl border border-white/8 bg-black/20 p-5 text-sm leading-7 text-text-secondary">
          <p class="text-text-primary">建议反馈时附上以下信息</p>
          <p class="mt-2">设备型号与系统版本、问题出现路径，以及相关截图或错误提示。</p>
        </div>
      </article>

      <article class="glass-panel p-8 sm:p-10">
        <p class="text-sm uppercase tracking-[0.2em] text-text-muted">Terms</p>
        <h2 class="mt-4 font-display text-3xl font-semibold text-text-primary">简要条款</h2>
        <div class="mt-8 space-y-4">
          <section
            v-for="term in terms"
            :key="term.title"
            class="rounded-2xl border border-white/8 bg-white/4 p-5"
          >
            <h3 class="font-display text-xl font-medium text-text-primary">{{ term.title }}</h3>
            <p class="mt-3 text-base leading-7 text-text-secondary">{{ term.content }}</p>
          </section>
        </div>

        <div class="mt-6 rounded-2xl border border-white/8 bg-black/20 p-5 text-sm leading-7 text-text-secondary">
          <p class="text-text-primary">补充说明</p>
          <p class="mt-2">
            本页内容用于官网展示与基础告知，后续如增加隐私政策、完整用户协议或数据同步功能，将同步更新条款内容与版本说明。
          </p>
          <RouterLink to="/privacy" class="mt-4 inline-flex text-text-primary transition hover:text-white">
            查看完整隐私政策
          </RouterLink>
        </div>
      </article>
    </section>
  </div>
</template>