<script lang="ts">
    import { onMount } from "svelte";
    import { api } from "./ksu";
    import { _ } from "svelte-i18n";
    import { Play, Square } from "lucide-svelte";

    let status = $state("");
    let isRunning = $state(false);
    let pid = $state("");
    let port = $state("");
    let ip = $state("");
    let isToggling = $state(false);

    // 新增状态：设置
    let autostart = $state(false);
    let keepData = $state(true);
    let isSavingSettings = $state(false);

    async function toggleSetting(type: "autostart" | "keepData") {
        if (isSavingSettings) return;
        isSavingSettings = true;
        try {
            if (type === "autostart") autostart = !autostart;
            if (type === "keepData") keepData = !keepData;
            await api("set_settings", String(autostart), String(keepData));
        } finally {
            isSavingSettings = false;
        }
    }

    async function checkStatus() {
        status = $_("app.status.checking");
        try {
            const res = await api("status");
            // res.stdout 是 "{"errno":0,"stdout":"{\"running\":...}","stderr":""}"
            const outer = JSON.parse(res.stdout);
            const data = JSON.parse(outer.stdout);
            isRunning = data.running;
            pid = data.pid || "";
            port = data.port || "22";
            status = isRunning
                ? $_("app.status.running")
                : $_("app.status.stopped");
        } catch (e) {
            console.error("[Status] Check failed:", e);
            status = $_("app.status.stopped");
            isRunning = false;
        }
    }

    async function toggleService() {
        isToggling = true;
        status = $_("app.status.toggling");
        try {
            if (isRunning) {
                await api("stop");
            } else {
                await api("start");
            }
        } finally {
            isToggling = false;
        }
        await checkStatus();
    }

    onMount(() => {
        checkStatus();
        api("get_ip")
            .then((res) => {
                const outer = JSON.parse(res.stdout);
                ip = outer.stdout.trim();
            })
            .catch(() => {});

        // 获取设置
        api("get_settings")
            .then((res) => {
                try {
                    const outer = JSON.parse(res.stdout);
                    // 业务 JSON 还在 stdout 里
                    const data = JSON.parse(outer.stdout);
                    autostart = data.autostart ?? false;
                    keepData = data.keep_data ?? true;
                } catch (e) {
                    console.error("[Settings] Parse error:", e, res.stdout);
                }
            })
            .catch((err) => {
                console.error("[Settings] Fetch error:", err);
            });
    });
</script>

<div
    class="bg-white dark:bg-slate-900 shadow-sm rounded-xl p-6 border border-slate-200 dark:border-slate-800"
>
    <h2 class="text-lg font-semibold mb-4">{$_("app.status.title")}</h2>

    <div class="mt-4 bg-slate-50 dark:bg-slate-800/50 p-4 rounded-lg space-y-2">
        <!-- 第一行：指示灯 + 状态文字 + 按钮 -->
        <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
                <div
                    class="w-3 h-3 rounded-full flex-shrink-0 {isRunning
                        ? 'bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]'
                        : 'bg-rose-500'}"
                ></div>
                <span class="font-medium">{status}</span>
            </div>

            <button
                onclick={toggleService}
                disabled={isToggling}
                title={isRunning
                    ? $_("app.status.btn_stop")
                    : $_("app.status.btn_start")}
                class="w-9 h-9 flex items-center justify-center rounded-full transition-colors disabled:opacity-50 {isRunning
                    ? 'bg-rose-100 text-rose-600 hover:bg-rose-200 dark:bg-rose-500/10 dark:text-rose-400 dark:hover:bg-rose-500/20'
                    : 'bg-emerald-100 text-emerald-600 hover:bg-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:hover:bg-emerald-500/20'}"
            >
                {#if isRunning}
                    <Square
                        class="w-4 h-4"
                        fill="currentColor"
                        stroke-width="0"
                    />
                {:else}
                    <Play
                        class="w-4 h-4"
                        fill="currentColor"
                        stroke-width="0"
                    />
                {/if}
            </button>
        </div>

        <!-- 第二行：IP / PID / Port 附加信息 -->
        {#if ip || (isRunning && pid)}
            <div class="pl-6 flex flex-col gap-0.5">
                {#if ip}
                    <span class="text-xs text-slate-400">IP: {ip}</span>
                {/if}
                {#if isRunning && pid}
                    <span class="text-xs text-slate-400">PID: {pid}</span>
                    <span class="text-xs text-slate-400">Port: {port}</span>
                {/if}
            </div>
        {/if}
    </div>

    <!-- 模块附加设置 (Autostart & Keep Data) -->
    <div
        class="mt-4 pt-4 border-t border-slate-100 dark:border-slate-800 space-y-4"
    >
        <h3
            class="text-sm font-semibold text-slate-600 dark:text-slate-300 mb-2"
        >
            {$_("app.status.settings")}
        </h3>

        <!-- 开机自启 -->
        <div class="flex items-start justify-between">
            <div class="flex flex-col gap-0.5">
                <span class="text-sm font-medium"
                    >{$_("app.status.autostart")}</span
                >
                <span class="text-xs text-slate-500 dark:text-slate-400"
                    >{$_("app.status.autostart_desc")}</span
                >
            </div>
            <button
                class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full transition-colors duration-200 focus:outline-none p-1 {autostart
                    ? 'bg-emerald-500'
                    : 'bg-slate-200 dark:bg-slate-700'}"
                role="switch"
                aria-checked={autostart}
                aria-label={$_("app.status.autostart")}
                onclick={() => toggleSetting("autostart")}
                disabled={isSavingSettings}
            >
                <span
                    class="pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow transition duration-200 ease-in-out {autostart
                        ? 'translate-x-5'
                        : 'translate-x-0'}"
                ></span>
            </button>
        </div>

        <!-- 卸载保留数据 -->
        <div class="flex items-start justify-between">
            <div class="flex flex-col gap-0.5">
                <span class="text-sm font-medium"
                    >{$_("app.status.keep_data")}</span
                >
                <span class="text-xs text-slate-500 dark:text-slate-400"
                    >{$_("app.status.keep_data_desc")}</span
                >
            </div>
            <button
                class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full transition-colors duration-200 focus:outline-none p-1 {keepData
                    ? 'bg-emerald-500'
                    : 'bg-slate-200 dark:bg-slate-700'}"
                role="switch"
                aria-checked={keepData}
                aria-label={$_("app.status.keep_data")}
                onclick={() => toggleSetting("keepData")}
                disabled={isSavingSettings}
            >
                <span
                    class="pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow transition duration-200 ease-in-out {keepData
                        ? 'translate-x-5'
                        : 'translate-x-0'}"
                ></span>
            </button>
        </div>
    </div>
</div>
