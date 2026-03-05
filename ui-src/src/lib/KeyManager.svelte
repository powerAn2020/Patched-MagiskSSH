<script lang="ts">
    import { onMount } from "svelte";
    import { api, apiWithStdin } from "./ksu";
    import { _ } from "svelte-i18n";
    import { Trash2, KeyRound, User, Users } from "lucide-svelte";

    type User = "root" | "shell";

    let activeUser = $state<User>("root");
    let keysByUser = $state<Record<User, string[]>>({ root: [], shell: [] });
    let newKey = $state("");
    let isAdding = $state(false);
    let isLoading = $state(false);

    const users: { id: User; label: string }[] = [
        { id: "root", label: "root" },
        { id: "shell", label: "shell" },
    ];

    // Reactive: current user's key list
    let keys = $derived(keysByUser[activeUser]);

    async function loadKeys(user: User) {
        isLoading = true;
        try {
            const res = await api("read_keys", user);
            keysByUser[user] = res.stdout.trim()
                ? res.stdout
                      .trim()
                      .split("\n")
                      .filter((k) => k.trim() !== "")
                : [];
        } catch {
            keysByUser[user] = [];
        } finally {
            isLoading = false;
        }
    }

    async function switchUser(user: User) {
        activeUser = user;
        // Lazy load: only fetch if not yet loaded
        if (keysByUser[user].length === 0) {
            await loadKeys(user);
        }
    }

    async function addKey() {
        if (!newKey.trim()) return;
        isAdding = true;
        try {
            await apiWithStdin(`add_key ${activeUser}`, newKey.trim());
            keysByUser[activeUser] = [...keysByUser[activeUser], newKey.trim()];
            newKey = "";
        } finally {
            isAdding = false;
        }
    }

    async function deleteKey(index: number) {
        const lineNum = index + 1;
        await api("delete_key", lineNum.toString(), activeUser);
        keysByUser[activeUser] = keysByUser[activeUser].filter(
            (_, i) => i !== index,
        );
    }

    onMount(() => loadKeys("root"));
</script>

<div
    class="bg-white dark:bg-slate-900 shadow-sm rounded-xl p-6 border border-slate-200 dark:border-slate-800"
>
    <!-- Header -->
    <div class="flex items-center gap-2 mb-5">
        <KeyRound class="w-5 h-5 text-indigo-500" />
        <h2 class="text-lg font-semibold">{$_("app.auth.title")}</h2>
    </div>

    <!-- User Tabs -->
    <div class="flex gap-1 p-1 bg-slate-100 dark:bg-slate-800 rounded-lg mb-5">
        {#each users as u}
            <button
                onclick={() => switchUser(u.id)}
                class="flex-1 flex items-center justify-center gap-1.5 py-1.5 text-sm font-medium rounded-md transition-all {activeUser ===
                u.id
                    ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100 shadow-sm'
                    : 'text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'}"
            >
                {#if u.id === "root"}
                    <User class="w-3.5 h-3.5" />
                {:else}
                    <Users class="w-3.5 h-3.5" />
                {/if}
                {u.label}
            </button>
        {/each}
    </div>

    <!-- Key list -->
    <div class="space-y-3 mb-5 min-h-[3rem]">
        {#if isLoading}
            <div
                class="animate-pulse bg-slate-100 dark:bg-slate-800 h-12 rounded-lg w-full"
            ></div>
        {:else if keys.length === 0}
            <p class="text-sm text-slate-500 italic py-3">
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
                        class="p-2 text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-500/10 rounded-md transition-colors"
                        title={$_("app.auth.btn_delete")}
                    >
                        <Trash2 class="w-4 h-4" />
                    </button>
                </div>
            {/each}
        {/if}
    </div>

    <!-- Add key -->
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
