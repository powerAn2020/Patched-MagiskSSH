<script lang="ts">
  import Dashboard from "./lib/Dashboard.svelte";
  import ConfigEditor from "./lib/ConfigEditor.svelte";
  import KeyManager from "./lib/KeyManager.svelte";
  import LogViewer from "./lib/LogViewer.svelte";
  import { _, isLoading, locale } from "svelte-i18n";
  import { debugEnabled, toggleDebug } from "./lib/ksu";
  import { Moon, Sun } from "lucide-svelte";

  // Normalize locale to 'zh'/'en' — navigator may return 'zh-CN', 'zh-TW', etc.
  let isZh = $derived(($locale ?? "").startsWith("zh"));

  function toggleLanguage() {
    locale.set(isZh ? "en" : "zh");
  }

  // --- Dark mode ---
  // 初始化：localstorage > 系统偏好
  const stored = localStorage.getItem("theme");
  let isDark = $state(
    stored
      ? stored === "dark"
      : window.matchMedia("(prefers-color-scheme: dark)").matches,
  );

  // 实时应用 dark 类到 html
  $effect(() => {
    document.documentElement.classList.toggle("dark", isDark);
    localStorage.setItem("theme", isDark ? "dark" : "light");
  });

  function toggleDark() {
    isDark = !isDark;
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

          <!-- 夜间模式切换 -->
          <button
            onclick={toggleDark}
            title={isDark
              ? isZh
                ? "切换为亮色模式"
                : "Light mode"
              : isZh
                ? "切换为深色模式"
                : "Dark mode"}
            class="w-8 h-8 flex items-center justify-center rounded-md transition-colors bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300"
          >
            {#if isDark}
              <Sun class="w-4 h-4" />
            {:else}
              <Moon class="w-4 h-4" />
            {/if}
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
