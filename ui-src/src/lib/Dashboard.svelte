<script lang="ts">
    import { onMount } from "svelte";
    import { exec, spawn } from "./ksu";
    import { _ } from "svelte-i18n";

    let status = $state("");
    let isRunning = $state(false);

    async function checkStatus() {
        status = $_("app.status.checking");
        // Assuming pidof sshd or similar logic stands here
        const res = await exec("pidof sshd");
        if (res.stdout.trim().length > 0) {
            status = $_("app.status.running");
            isRunning = true;
        } else {
            status = $_("app.status.stopped");
            isRunning = false;
        }
    }

    async function toggleService() {
        status = $_("app.status.toggling");
        // Dummy toggle logic - replace with actual Magisk module action script
        if (isRunning) {
            await exec("pkill sshd");
        } else {
            // Starting SSHD, this might be a slow operation so spawn could be used for logs, but we'll use exec for now
            await exec("sshd");
        }
        setTimeout(checkStatus, 1000);
    }

    onMount(() => {
        checkStatus();
    });
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
            <span class="font-medium">{status}</span>
        </div>

        <button
            onclick={toggleService}
            class="px-4 py-2 rounded-md text-sm font-medium transition-colors {isRunning
                ? 'bg-rose-100 text-rose-700 hover:bg-rose-200 dark:bg-rose-500/10 dark:text-rose-400 dark:hover:bg-rose-500/20'
                : 'bg-emerald-100 text-emerald-700 hover:bg-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:hover:bg-emerald-500/20'}"
        >
            {isRunning ? $_("app.status.btn_stop") : $_("app.status.btn_start")}
        </button>
    </div>
</div>
