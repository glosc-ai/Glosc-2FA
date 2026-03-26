<script setup lang="ts">
const appStorePlaceholder = "https://apps.apple.com/cn/app/id6760886600";

const highlights = [
    "支持 iPhone 与 iPad 上的 TOTP / HOTP 验证码管理",
    "支持二维码扫描导入与 otpauth 链接解析",
    "支持 Keychain 安全存储与设备身份验证解锁",
    "支持验证码复制、倒计时展示与 HOTP 计数推进",
];
</script>

<template>
    <div class="shell py-16 sm:py-20">
        <section class="mx-auto max-w-4xl text-center">
            <p class="text-sm uppercase tracking-[0.24em] text-text-muted">
                Download
            </p>
            <h1
                class="mt-4 font-display text-4xl font-semibold tracking-tight text-text-primary sm:text-5xl">
                即将在 App Store 上线
            </h1>
            <p
                class="mx-auto mt-6 max-w-2xl text-lg leading-8 text-text-secondary">
                下载链接已预留至 Apple App
                Store。当前版本仍在审核中，审核通过后即可直接跳转下载。
            </p>
        </section>

        <section
            class="mx-auto mt-12 grid max-w-6xl gap-6 lg:grid-cols-[minmax(0,1.1fr)_minmax(320px,0.9fr)]">
            <article class="glass-panel p-8 sm:p-10">
                <div
                    class="flex flex-col gap-6 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                        <p
                            class="text-sm uppercase tracking-[0.22em] text-text-muted">
                            App Store
                        </p>
                        <h2
                            class="mt-3 font-display text-3xl font-semibold text-text-primary">
                            Glosc Authenticator
                        </h2>
                    </div>
                </div>

                <div class="mt-8 flex flex-col gap-4 sm:flex-row">
                    <a
                        :href="appStorePlaceholder"
                        class="button-primary"
                        target="_blank"
                        rel="noreferrer">
                        前往 App Store
                    </a>
                    <RouterLink to="/support" class="button-secondary"
                        >查看技术支持</RouterLink
                    >
                </div>

                <div class="mt-10 grid gap-4 sm:grid-cols-2">
                    <div
                        v-for="highlight in highlights"
                        :key="highlight"
                        class="rounded-2xl border border-white/8 bg-black/20 p-4 text-text-secondary">
                        {{ highlight }}
                    </div>
                </div>
            </article>

            <aside class="glass-panel p-8">
                <p class="text-sm uppercase tracking-[0.22em] text-text-muted">
                    安装说明
                </p>
                <ol
                    class="mt-5 space-y-4 text-sm leading-7 text-text-secondary">
                    <li>1. 点击 App Store 占位链接进入 Apple 官方下载页。</li>
                    <li>
                        2. 审核通过后，可在 iPhone 或 iPad 上直接获取并安装。
                    </li>
                    <li>
                        3. 首次启动后，建议开启设备身份验证保护并导入现有 OTP
                        账号。
                    </li>
                </ol>

                <div
                    class="mt-8 rounded-2xl border border-white/8 bg-white/4 p-5">
                    <p
                        class="text-sm uppercase tracking-[0.2em] text-text-muted">
                        系统要求
                    </p>
                    <p class="mt-3 text-text-primary">
                        适用于 Apple 平台，当前以 iOS / iPadOS 版本为主。
                    </p>
                    <p class="mt-2 text-sm leading-7 text-text-secondary">
                        未来版本将逐步扩展更多 Apple 设备形态与协同能力。
                    </p>
                </div>
            </aside>
        </section>
    </div>
</template>
