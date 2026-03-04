<script lang="ts">
    import { onMount } from "svelte";
    import { api } from "./ksu";
    import { _ } from "svelte-i18n";

    let status = $state("");
    let isRunning = $state(false);
    let pid = $state("");
    let port = $state("");
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

    onMount(checkStatus);
</script>

<div
    class="bg-white dark:bg-slate-900 shadow-sm rounded-xl p-6 border border-slate-200 dark:border-slate-800"
>
    <h2 class="text-lg font-semibold mb-4">{$_("app.status.title")}</h2>

    <div
        class="flex items-center justify-between mt-4 bg-slate-50 dark:bg-slate-800/50 p-4 rounded-lg"
    >
        <div class="flex items-center gap-3">
            <div
                class="w-3 h-3 rounded-full {isRunning
                    ? 'bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]'
                    : 'bg-rose-500'}"
            ></div>
            <div>
                <span class="font-medium">{status}</span>
                {#if isRunning && pid}
                    <span class="text-xs text-slate-400 ml-2"
                        >PID: {pid} · Port: {port}</span
                    >
                {/if}
            </div>
        </div>

        <button
            onclick={toggleService}
            disabled={isToggling}
            class="px-4 py-2 rounded-md text-sm font-medium transition-colors disabled:opacity-50 {isRunning
                ? 'bg-rose-100 text-rose-700 hover:bg-rose-200 dark:bg-rose-500/10 dark:text-rose-400 dark:hover:bg-rose-500/20'
                : 'bg-emerald-100 text-emerald-700 hover:bg-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:hover:bg-emerald-500/20'}"
        >
            {isRunning ? $_("app.status.btn_stop") : $_("app.status.btn_start")}
        </button>
    </div>
</div>
