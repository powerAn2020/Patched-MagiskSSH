<script lang="ts">
    import { exec } from "./ksu";
    import { onMount, tick } from "svelte";
    import { _ } from "svelte-i18n";

    let configContent = $state("");
    let isSaving = $state(false);

    async function loadConfig() {
        configContent = $_("app.config.editor_placeholder");
        const res = await exec("cat /data/adb/modules/MagiskSSH/sshd_config");
        configContent = res.stdout || "File not found or empty.";
    }

    async function saveConfig() {
        isSaving = true;
        try {
            const safeContent = configContent.replace(/'/g, "'\\''");
            await exec(
                `echo '${safeContent}' > /data/adb/modules/MagiskSSH/sshd_config`,
            );
        } finally {
            isSaving = false;
        }
    }

    onMount(loadConfig);
</script>

<div
    class="bg-white dark:bg-slate-900 shadow-sm rounded-xl p-6 border border-slate-200 dark:border-slate-800 mt-6"
>
    <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-semibold">{$_("app.config.title")}</h2>
        <button
            onclick={saveConfig}
            disabled={isSaving}
            class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-md text-sm font-medium transition-colors disabled:opacity-50"
        >
            {isSaving ? $_("app.config.btn_saving") : $_("app.config.btn_save")}
        </button>
    </div>

    <textarea
        bind:value={configContent}
        class="w-full h-64 p-4 font-mono text-sm bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-y"
        spellcheck="false"
    ></textarea>
</div>
