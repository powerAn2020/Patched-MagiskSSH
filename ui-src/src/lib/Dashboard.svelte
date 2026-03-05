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

    async function checkStatus() {
        status = $_("app.status.checking");
        try {
            const res = await api("status");
            const data = JSON.parse(res.stdout);
            isRunning = data.running;
            pid = data.pid || "";
            port = data.port || "22";
            status = isRunning
                ? $_("app.status.running")
                : $_("app.status.stopped");
        } catch {
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
                ip = res.stdout.trim();
            })
            .catch(() => {});
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
                    <span class="text-xs text-slate-400"
                        >PID: {pid} · Port: {port}</span
                    >
                {/if}
            </div>
        {/if}
    </div>
</div>
