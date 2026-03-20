<script setup lang="ts">
const sections = [
  {
    title: '信息收集范围',
    content:
      'Glosc 2FA 以本地使用为核心。应用主要处理你主动添加或导入的 OTP 账号信息，包括账号名称、发行方、配置参数以及与验证码生成相关的数据。',
  },
  {
    title: '数据存储方式',
    content:
      '共享密钥等敏感信息优先存储于设备的安全存储能力中，例如 Keychain。页面展示信息与必要配置可能保存在本地持久化存储中，用于支持日常使用体验。',
  },
  {
    title: '数据使用目的',
    content:
      '这些数据仅用于本地生成验证码、展示账号列表、支持导入导出流程，以及保障应用在设备上的正常运行，不用于无关广告或画像用途。',
  },
  {
    title: '第三方与系统能力',
    content:
      '应用可能调用 Apple 提供的系统能力，例如相机扫码、设备身份验证或安全存储接口。相关能力的实际行为同时受 Apple 平台系统规则约束。',
  },
  {
    title: '你的控制权',
    content:
      '你可以自行新增、编辑或删除账号数据，并根据产品后续版本提供的功能决定是否启用同步、备份或其他可选能力。',
  },
  {
    title: '政策更新',
    content:
      '当产品功能、数据处理方式或适用法律要求发生变化时，本隐私政策可能更新。更新后内容将发布在官网中，并以最新版本为准。',
  },
]
</script>

<template>
  <div class="shell py-16 sm:py-20 lg:py-24">
    <section class="mx-auto max-w-3xl text-center">
      <p class="text-sm uppercase tracking-[0.24em] text-text-muted">Privacy</p>
      <h1 class="mt-4 font-display text-4xl font-semibold tracking-tight text-text-primary sm:text-5xl">
        隐私政策
      </h1>
      <p class="mt-6 text-lg leading-8 text-text-secondary sm:text-xl">
        Glosc 2FA 重视你的数据安全与隐私。本页面用于说明应用在当前版本中的数据处理原则与基本保护方式。
      </p>
    </section>

    <section class="mx-auto mt-12 max-w-4xl space-y-4">
      <article
        v-for="section in sections"
        :key="section.title"
        class="glass-panel p-8 sm:p-10"
      >
        <h2 class="font-display text-2xl font-semibold text-text-primary sm:text-3xl">
          {{ section.title }}
        </h2>
        <p class="mt-4 text-base leading-8 text-text-secondary sm:text-lg">
          {{ section.content }}
        </p>
      </article>

      <article class="glass-panel p-8 sm:p-10">
        <p class="text-sm uppercase tracking-[0.2em] text-text-muted">Contact</p>
        <h2 class="mt-4 font-display text-2xl font-semibold text-text-primary sm:text-3xl">
          隐私相关联系
        </h2>
        <p class="mt-4 text-base leading-8 text-text-secondary sm:text-lg">
          如对本政策内容、数据处理方式或账号安全有疑问，可通过支持邮箱联系：xm@aoe.top。
        </p>
      </article>
    </section>
  </div>
</template>