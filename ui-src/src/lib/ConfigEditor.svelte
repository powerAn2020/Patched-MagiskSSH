<script lang="ts">
    import { api, apiWithStdin } from "./ksu";
    import { onMount } from "svelte";
    import { _ } from "svelte-i18n";

    let configContent = $state("");
    let isSaving = $state(false);
    let isLoading = $state(true);

    async function loadConfig() {
        isLoading = true;
        try {
            const res = await api("read_config");
            // api.sh read_config returns base64-encoded content
            if (res.stdout.trim()) {
                configContent = decodeURIComponent(
                    escape(atob(res.stdout.trim())),
                );
            } else {
                configContent = "";
            }
        } catch {
            configContent = "";
        } finally {
            isLoading = false;
        }
    }

    async function saveConfig() {
        isSaving = true;
        try {
            await apiWithStdin("write_config", configContent);
        } finally {
            isSaving = false;
        }
    }

    onMount(loadConfig);
</script>

<div
    class="bg-white dark:bg-slate-900 shadow-sm rounded-xl p-6 border border-slate-200 dark:border-slate-800"
>
    <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-semibold">{$_("app.config.title")}</h2>
        <button
            onclick={saveConfig}
            disabled={isSaving || isLoading}
            class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-md text-sm font-medium transition-colors disabled:opacity-50"
        >
            {isSaving ? $_("app.config.btn_saving") : $_("app.config.btn_save")}
        </button>
    </div>

    {#if isLoading}
        <div
            class="w-full h-64 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg animate-pulse"
        ></div>
    {:else}
        <textarea
            bind:value={configContent}
            class="w-full h-64 p-4 font-mono text-sm bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-y overflow-x-auto"
            spellcheck="false"
            wrap="off"
        ></textarea>
    {/if}
</div>
