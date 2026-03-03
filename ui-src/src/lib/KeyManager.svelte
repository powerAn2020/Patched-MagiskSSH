<script lang="ts">
    import { onMount } from "svelte";
    import { exec } from "./ksu";
    import { _ } from "svelte-i18n";
    import { Trash2, KeyRound } from "lucide-svelte";

    const KEYS_FILE = "/data/adb/modules/MagiskSSH/authorized_keys"; // May need to be ~/.ssh/authorized_keys depending on module impl
    let keys: string[] = $state([]);
    let newKey = $state("");
    let isAdding = $state(false);
    let isLoading = $state(true);

    async function loadKeys() {
        isLoading = true;
        try {
            const res = await exec(`cat ${KEYS_FILE}`);
            if (res.stdout.trim()) {
                keys = res.stdout
                    .trim()
                    .split("\n")
                    .filter((k) => k.trim() !== "");
            } else {
                keys = [];
            }
        } catch (e) {
            console.error(e);
            keys = [];
        } finally {
            isLoading = false;
        }
    }

    async function saveKeys() {
        const content = keys.join("\n");
        await exec(`cat <<EOF > ${KEYS_FILE}\n${content}\nEOF`);
    }

    async function addKey() {
        if (!newKey.trim()) return;
        isAdding = true;
        keys = [...keys, newKey.trim()];
        await saveKeys();
        newKey = "";
        isAdding = false;
    }

    async function deleteKey(index: number) {
        keys.splice(index, 1);
        await saveKeys();
        // Re-assign to trigger reactivity
        keys = [...keys];
    }

    onMount(loadKeys);
</script>

<div
    class="bg-white dark:bg-slate-900 shadow-sm rounded-xl p-6 border border-slate-200 dark:border-slate-800 mt-6"
>
    <div class="flex items-center gap-2 mb-6">
        <KeyRound class="w-5 h-5 text-indigo-500" />
        <h2 class="text-lg font-semibold">{$_("app.auth.title")}</h2>
    </div>

    <div class="space-y-4 mb-6">
        {#if isLoading}
            <div
                class="animate-pulse bg-slate-100 dark:bg-slate-800 h-12 rounded-lg w-full"
            ></div>
        {:else if keys.length === 0}
            <p class="text-sm text-slate-500 italic py-4">
                {$_("app.auth.empty")}
            </p>
        {:else}
            {#each keys as key, index}
                <div
                    class="group flex items-center justify-between gap-4 p-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-800 rounded-lg transition-all hover:bg-white dark:hover:bg-slate-800 hover:shadow-sm"
                >
                    <div class="flex-1 min-w-0">
                        <p
                            class="text-sm font-mono truncate text-slate-600 dark:text-slate-400"
                            title={key}
                        >
                            {key}
                        </p>
                    </div>
                    <button
                        onclick={() => deleteKey(index)}
                        class="p-2 text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-500/10 rounded-md transition-colors opacity-0 group-hover:opacity-100 focus:opacity-100"
                        title={$_("app.auth.btn_delete")}
                    >
                        <Trash2 class="w-4 h-4" />
                    </button>
                </div>
            {/each}
        {/if}
    </div>

    <div class="flex gap-3">
        <input
            type="text"
            bind:value={newKey}
            placeholder={$_("app.auth.input_placeholder")}
            class="flex-1 px-4 py-2 text-sm bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            onkeydown={(e) => e.key === "Enter" && addKey()}
        />
        <button
            onclick={addKey}
            disabled={isAdding || !newKey.trim()}
            class="px-5 py-2 whitespace-nowrap bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm font-medium transition-colors disabled:opacity-50"
        >
            {isAdding ? $_("app.auth.btn_adding") : $_("app.auth.btn_add")}
        </button>
    </div>
</div>
