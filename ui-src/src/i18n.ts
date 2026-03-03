import { init, addMessages, getLocaleFromNavigator } from 'svelte-i18n';

import en from './locales/en.json';
import zh from './locales/zh.json';

addMessages('en', en);
addMessages('zh', zh);

init({
    fallbackLocale: 'en',
    initialLocale: getLocaleFromNavigator(),
});
