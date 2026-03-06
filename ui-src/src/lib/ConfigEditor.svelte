<script lang="ts">
    import { api, apiWithStdin } from "./ksu";
    import { onMount } from "svelte";
    import { _ } from "svelte-i18n";
    import Toast from "./Toast.svelte";

    let configContent = $state("");
    let isSaving = $state(false);
    let isLoading = $state(true);
    let toast = $state<{ message: string; type: "success" | "error" } | null>(
        null,
    );

    async function loadConfig() {
        isLoading = true;
        try {
            const res = await api("read_config");
            const outer = JSON.parse(res.stdout);
            const b64 = outer.stdout || "";
            if (b64.trim()) {
                configContent = decodeURIComponent(escape(atob(b64.trim())));
            } else {
                configContent = "";
            }
        } catch (e) {
            console.error("[Config] Load failed", e);
            configContent = "";
        } finally {
            isLoading = false;
        }
    }

    async function saveConfig() {
        isSaving = true;
        toast = null; // Clear previous toast
        try {
            await apiWithStdin("write_config", configContent);
            toast = { message: $_("app.config.save_success"), type: "success" };
        } catch (e: any) {
            toast = {
                message: $_("app.config.save_failed") + ": " + e.message,
                type: "error",
            };
        } finally {
            isSaving = false;
        }
    }

    onMount(loadConfig);
</script>

{#if toast}
    <Toast
        message={toast.message}
        type={toast.type}
        onclose={() => (toast = null)}
    />
{/if}

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
