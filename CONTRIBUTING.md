# Contributing

Thank you for helping. The most useful contributions are reports of scientific
or technical mistakes in a lesson: open an issue with the "Report a mistake"
template and include the lesson link. Contributions to lesson text are accepted
under the content licence (CC BY-NC-SA 4.0); contributions to code under MIT.

## Commands

| Command | What it does |
| --- | --- |
| `npm ci` | Install the pinned dependencies |
| `npm run dev` | Local development server |
| `npm run build` | Content checks, `astro build`, Pagefind index, page-weight budget. Any failure stops the build. |
| `npm run check:content` | Content checks only |
| `npm test` | Unit tests (`node --test`) |

## Lessons

- One file per lesson in each language: `content/lessons/<ar|en>/NN-NN-slug.mdx`.
  The slug is the lesson id, its URL (`/lesson/<slug>/`) and its progress key, so it never changes.
- Station, order, level and time come from `src/data/roadmap.yaml`; the lesson frontmatter must match it.
- Sections are written in a fixed order (`why`, `before-after`, `gui`, `script`, `values`,
  `mistakes`, `verify`, `methods`). The template decides which ones are shown and which are folded.
- Allowed components: `MenuPath`, `UiLabel`, `En`, `Callout`, `Figure`, `ImageSpec`, `Methods`,
  `BeforeAfter`, `YouTube`, `FilterDemo`, `RerefDemo`, `EpochRejectDemo`, `IcaGameTeaser`.
  No `import` lines; components are provided by the template.
- Menu paths use `>` between items: `<MenuPath>Tools > Filter the data</MenuPath>`.
- Every `Figure` names its `source` (a dataset code, `eeglab-ui` or `original`); the licence
  line under the image is generated from `src/data/datasets.yaml`.
- Code blocks are MATLAB unless marked otherwise and are always shown left to right.
- `progress-slots.lock` and `ica-daily.lock` are append-only: add new lines at the end, never
  reorder or remove one.

`npm run check:content` explains each problem with the file and line.

## Code style

- Static output only: no server code and no scripts or fonts loaded from other sites.
- Each page stays under 500 KB gzipped and each script under 10 KB gzipped (`check-budget.mjs`).
- Internal links go through `url()` so the Arabic and English sites stay in step.
- Interface text lives in `src/i18n`, never in templates.
- Comments are short, in English, and explain why rather than what.
- Commit messages follow Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`).
