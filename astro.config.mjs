import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';
import rehypeLesson from './src/lib/rehype-lesson.mjs';
import rehypeTerms from './src/lib/rehype-terms.mjs';
import { matlabLight, matlabDark } from './src/lib/shiki-themes.mjs';

export default defineConfig({
  site: process.env.SITE_URL ?? 'https://simplyeeglab.pages.dev',
  base: process.env.SITE_BASE ?? '/',
  output: 'static',
  trailingSlash: 'always',
  build: { format: 'directory', inlineStylesheets: 'never' },
  integrations: [
    mdx(),
    sitemap({
      i18n: { defaultLocale: 'ar', locales: { ar: 'ar', en: 'en' } },
      filter: (page) => !/\/(dev|card|map)\//.test(page) && !/\/404\/?$/.test(page),
    }),
  ],
  i18n: {
    locales: ['ar', 'en'],
    defaultLocale: 'ar',
    routing: { prefixDefaultLocale: false },
  },
  markdown: {
    shikiConfig: { themes: { light: matlabLight, dark: matlabDark }, defaultColor: false },
    rehypePlugins: [rehypeLesson, rehypeTerms],
  },
  security: {
    // Same-origin only, plus the privacy-enhanced YouTube player and Cloudflare's analytics beacon.
    // Search runs WebAssembly; code highlighting needs inline style attributes.
    csp: {
      directives: [
        "default-src 'self'",
        "img-src 'self' data:",
        "font-src 'self'",
        "connect-src 'self' https://cloudflareinsights.com",
        "frame-src https://www.youtube-nocookie.com",
        "worker-src 'self' blob:",
        "object-src 'none'",
        "base-uri 'self'",
        "form-action 'self'",
      ],
      scriptDirective: { resources: ["'self'", 'https://static.cloudflareinsights.com', "'wasm-unsafe-eval'"] },
      styleDirective: { resources: ["'self'", { kind: 'attribute', resource: "'unsafe-inline'" }] },
    },
  },
  devToolbar: { enabled: false },
});
