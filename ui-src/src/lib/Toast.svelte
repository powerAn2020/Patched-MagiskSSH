<script lang="ts">
    import { onMount, onDestroy } from "svelte";

    let {
        message = "",
        type = "success",
        duration = 3000,
        onclose = null,
    } = $props<{
        message: string;
        type?: "success" | "error";
        duration?: number;
        onclose?: () => void;
    }>();

    let visible = $state(true);
    let timer: number;

    onMount(() => {
        timer = setTimeout(() => {
            close();
        }, duration);
    });

    onDestroy(() => {
        if (timer) clearTimeout(timer);
    });

    function close() {
        visible = false;
        if (onclose) onclose();
    }
</script>

{#if visible}
    <div
        class="fixed bottom-4 right-4 flex items-center p-4 mb-4 text-sm rounded-lg shadow-lg transition-all duration-300 transform translate-y-0 opacity-100 z-50
        {type === 'success'
            ? 'text-green-800 bg-green-50 dark:bg-slate-800 dark:text-green-400 border border-green-200 dark:border-green-800'
            : 'text-red-800 bg-red-50 dark:bg-slate-800 dark:text-red-400 border border-red-200 dark:border-red-800'}"
        role="alert"
    >
        {#if type === "success"}
            <svg
                class="flex-shrink-0 inline w-4 h-4 mr-3"
                aria-hidden="true"
                xmlns="http://www.w3.org/2000/svg"
                fill="currentColor"
                viewBox="0 0 20 20"
            >
                <path
                    d="M10 .5a9.5 9.5 0 1 0 9.5 9.5A9.51 9.51 0 0 0 10 .5Zm3.707 8.207-4 4a1 1 0 0 1-1.414 0l-2-2a1 1 0 0 1 1.414-1.414L9 10.586l3.293-3.293a1 1 0 0 1 1.414 1.414Z"
                />
            </svg>
        {:else}
            <svg
                class="flex-shrink-0 inline w-4 h-4 mr-3"
                aria-hidden="true"
                xmlns="http://www.w3.org/2000/svg"
                fill="currentColor"
                viewBox="0 0 20 20"
            >
                <path
                    d="M10 .5a9.5 9.5 0 1 0 9.5 9.5A9.51 9.51 0 0 0 10 .5Zm3.707 11.793a1 1 0 1 1-1.414 1.414L10 11.414l-2.293 2.293a1 1 0 0 1-1.414-1.414L8.586 10 6.293 7.707a1 1 0 0 1 1.414-1.414L10 8.586l2.293-2.293a1 1 0 0 1 1.414 1.414L11.414 10l2.293 2.293Z"
                />
            </svg>
        {/if}
        <span class="sr-only">Icon</span>
        <div>
            <span class="font-medium">{message}</span>
        </div>
        <button
            type="button"
            onclick={close}
            class="ml-auto -mx-1.5 -my-1.5 rounded-lg focus:ring-2 focus:ring-slate-400 p-1.5 inline-flex items-center justify-center h-8 w-8
            {type === 'success'
                ? 'text-green-500 hover:bg-green-100 dark:text-green-400 dark:hover:bg-slate-700'
                : 'text-red-500 hover:bg-red-100 dark:text-red-400 dark:hover:bg-slate-700'}"
            data-dismiss-target="#alert-1"
            aria-label="Close"
        >
            <span class="sr-only">Close</span>
            <svg
                class="w-3 h-3"
                aria-hidden="true"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 14 14"
            >
                <path
                    stroke="currentColor"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="m1 1 6 6m0 0 6 6M7 7l6-6M7 7l-6 6"
                />
            </svg>
        </button>
    </div>
{/if}
