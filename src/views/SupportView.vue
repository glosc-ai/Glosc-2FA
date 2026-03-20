<script setup lang="ts">
const supportEmail = 'support@gloscai.com'

const terms = [
  {
    title: '使用说明',
    content:
      'Glosc Authenticator 用于在 Apple 平台本地管理 OTP 账号并生成动态验证码。你应自行确认导入账号的来源可信，并妥善保管设备访问权限。',
  },
  {
    title: '数据与安全',
    content:
      '应用优先使用本地存储与 Keychain 保护共享密钥。你理解并同意，若设备被越狱、遭受恶意软件攻击或被他人未授权访问，可能导致数据泄露风险。',
  },
  {
    title: '服务状态',
    content:
      '当前官网与应用仍处于持续迭代阶段。功能、兼容性与下载方式可能根据审核、系统更新或产品规划发生调整。',
  },
]
</script>

<template>
  <div class="shell py-16 sm:py-20">
    <section class="mx-auto max-w-3xl text-center">
      <p class="text-sm uppercase tracking-[0.24em] text-text-muted">Support</p>
      <h1 class="mt-4 font-display text-4xl font-semibold tracking-tight text-text-primary sm:text-5xl">
        技术支持与协议条款
      </h1>
      <p class="mt-6 text-lg leading-8 text-text-secondary">
        如遇到导入失败、验证码异常、数据保护或下载问题，可通过下方渠道联系。页面同时提供当前版本的简要使用条款说明。
      </p>
    </section>

    <section class="mt-12 grid gap-6 lg:grid-cols-[minmax(300px,0.82fr)_minmax(0,1.18fr)]">
      <aside class="glass-panel p-8">
        <p class="text-sm uppercase tracking-[0.2em] text-text-muted">联系方式</p>
        <h2 class="mt-4 font-display text-2xl font-semibold text-text-primary">技术支持</h2>
        <p class="mt-4 text-base leading-7 text-text-secondary">
          邮件支持适用于下载、导入、账号管理、验证码显示异常等问题反馈。
        </p>

        <div class="mt-6 rounded-2xl border border-white/8 bg-white/4 p-5">
          <p class="text-sm text-text-muted">支持邮箱</p>
          <a :href="`mailto:${supportEmail}`" class="mt-2 inline-block font-display text-xl text-text-primary">
            {{ supportEmail }}
          </a>
        </div>

        <div class="mt-6 rounded-2xl border border-white/8 bg-black/20 p-5 text-sm leading-7 text-text-secondary">
          <p class="text-text-primary">建议反馈时附上以下信息：</p>
          <ul class="mt-3 space-y-2">
            <li>设备型号与系统版本</li>
            <li>问题出现的操作路径</li>
            <li>相关截图或错误提示</li>
          </ul>
        </div>
      </aside>

      <article class="glass-panel p-8 sm:p-10">
        <p class="text-sm uppercase tracking-[0.2em] text-text-muted">Terms</p>
        <h2 class="mt-4 font-display text-3xl font-semibold text-text-primary">协议条款</h2>
        <div class="mt-8 space-y-6">
          <section
            v-for="term in terms"
            :key="term.title"
            class="rounded-2xl border border-white/8 bg-white/4 p-5"
          >
            <h3 class="font-display text-xl font-medium text-text-primary">{{ term.title }}</h3>
            <p class="mt-3 text-base leading-7 text-text-secondary">{{ term.content }}</p>
          </section>
        </div>

        <div class="mt-8 rounded-2xl border border-white/8 bg-black/20 p-5 text-sm leading-7 text-text-secondary">
          <p class="text-text-primary">补充说明</p>
          <p class="mt-2">
            本页内容用于官网展示与基础告知，后续如增加隐私政策、完整用户协议或数据同步功能，将同步更新条款内容与版本说明。
          </p>
        </div>
      </article>
    </section>
  </div>
</template>