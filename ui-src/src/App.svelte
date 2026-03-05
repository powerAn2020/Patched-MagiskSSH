<script lang="ts">
  import Dashboard from "./lib/Dashboard.svelte";
  import ConfigEditor from "./lib/ConfigEditor.svelte";
  import KeyManager from "./lib/KeyManager.svelte";
  import LogViewer from "./lib/LogViewer.svelte";
  import { _, isLoading, locale } from "svelte-i18n";
  import { debugEnabled, toggleDebug } from "./lib/ksu";

  // Normalize locale to 'zh'/'en' — navigator may return 'zh-CN', 'zh-TW', etc.
  let isZh = $derived(($locale ?? "").startsWith("zh"));

  function toggleLanguage() {
    locale.set(isZh ? "en" : "zh");
  }
</script>

{#if $isLoading}
  <div
    class="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-slate-950"
  >
    <div
      class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"
    ></div>
  </div>
{:else}
  <div
    class="min-h-screen bg-gray-50 text-slate-800 dark:bg-slate-950 dark:text-slate-200"
  >
    <header
      class="bg-white px-6 py-4 shadow-sm dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800"
    >
      <div class="max-w-4xl mx-auto flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div class="bg-indigo-600 p-2 rounded-lg shadow-md flex-shrink-0">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="text-white"
              ><path d="M4 17V4a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v13" /><path
                d="M2 20a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2"
              /><path d="M10 8h.01" /><path d="M14 8h.01" /><path
                d="M10 12h.01"
              /><path d="M14 12h.01" /></svg
            >
          </div>
          <h1 class="text-xl font-semibold tracking-tight truncate">
            {$_("app.title")}
          </h1>
        </div>

        <div class="flex items-center gap-2">
          <button
            onclick={toggleDebug}
            title={$debugEnabled
              ? isZh
                ? "关闭调试模式"
                : "Disable debug"
              : isZh
                ? "开启调试模式"
                : "Enable debug"}
            class="px-3 py-1.5 text-xs font-medium rounded-md transition-colors {$debugEnabled
              ? 'bg-orange-100 text-orange-700 hover:bg-orange-200 dark:bg-orange-500/20 dark:text-orange-300 dark:hover:bg-orange-500/30'
              : 'bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-500 dark:text-slate-400'}"
          >
            🐛 {$debugEnabled
              ? isZh
                ? "调试"
                : "Debug"
              : isZh
                ? "调试"
                : "Debug"}
          </button>

          <button
            onclick={toggleLanguage}
            class="px-3 py-1.5 text-xs font-medium bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 rounded-md transition-colors"
          >
            {isZh ? "En" : "中"}
          </button>
        </div>
      </div>
    </header>

    <main class="max-w-4xl mx-auto p-6 space-y-6">
      <Dashboard />
      <ConfigEditor />
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <KeyManager />
        <LogViewer />
      </div>
    </main>
  </div>
{/if}
