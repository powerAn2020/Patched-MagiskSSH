<script lang="ts">
    import { onMount, onDestroy } from "svelte";
    import { spawnLogTail } from "./ksu";
    import { _ } from "svelte-i18n";
    import { Terminal } from "lucide-svelte";

    let logs: string[] = $state([]);
    let logsContainer: HTMLElement;
    let killSpawn: (() => void) | null = null;
    let autoScroll = $state(true);

    function startTail() {
        killSpawn = spawnLogTail(
            (chunk) => {
                logs = [...logs, ...chunk.split("\n").filter(Boolean)];
                if (logs.length > 200) {
                    logs = logs.slice(-200);
                }
                if (autoScroll && logsContainer) {
                    requestAnimationFrame(() => {
                        logsContainer.scrollTop = logsContainer.scrollHeight;
                    });
                }
            },
            (err) => console.error("Log error:", err),
            (code) => console.log(`Tail exited with code ${code}`),
        );
    }

    function clearLogs() {
        logs = [];
    }

    onMount(startTail);

    onDestroy(() => {
        if (killSpawn) killSpawn();
    });

    function handleScroll() {
        if (!logsContainer) return;
        const { scrollTop, scrollHeight, clientHeight } = logsContainer;
        autoScroll = scrollHeight - scrollTop - clientHeight < 10;
    }
</script>

<div
    class="bg-slate-950 shadow-sm rounded-xl border border-slate-800 overflow-hidden flex flex-col h-[400px]"
>
    <div
        class="flex items-center justify-between px-4 py-3 bg-slate-900 border-b border-slate-800"
    >
        <div class="flex items-center gap-2">
            <Terminal class="w-4 h-4 text-emerald-400" />
            <h2 class="text-sm font-semibold text-slate-200">
                {$_("app.logs.title")}
            </h2>
            {#if autoScroll}
                <span class="flex h-2 w-2 relative ml-2">
                    <span
                        class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"
                    ></span>
                    <span
                        class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"
                    ></span>
                </span>
            {/if}
        </div>
        <button
            onclick={clearLogs}
            class="text-xs font-medium text-slate-400 hover:text-white transition-colors px-2 py-1 rounded"
        >
            {$_("app.logs.btn_clear")}
        </button>
    </div>

    <div
        bind:this={logsContainer}
        onscroll={handleScroll}
        class="flex-1 p-4 overflow-y-auto font-mono text-xs leading-5 text-emerald-400/90 whitespace-pre-wrap selection:bg-emerald-900/50"
    >
        {#if logs.length === 0}
            <p class="text-slate-600 italic">Waiting for logs...</p>
        {:else}
            {#each logs as logRow}
                <div class="break-all">{logRow}</div>
            {/each}
        {/if}
    </div>
</div>
