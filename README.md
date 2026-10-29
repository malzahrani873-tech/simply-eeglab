# Simply EEGLAB · EEGLAB ببساطة

A free, bilingual (Arabic and English) site that teaches EEGLAB as a roadmap:
11 stations and 62 short lessons, each one step of a single analysis project,
from a raw recording to group statistics. Each lesson shows the menu path, the
matching script, the values to choose, common mistakes and how to check the
result. There are interactive demos, end-of-station quizzes, an ICA component
game and a printable reference card for every lesson.

There are no accounts and no server. Progress is stored in the learner's browser
and moves between devices with a short code, a link or a file.

## Running locally

Requires Node 24 (see `.nvmrc`).

```sh
npm ci
npm run dev            # local server at http://localhost:4321
npm run build          # content checks, build, search index, page-weight budget
npm run preview        # serve the built site
npm test               # unit tests
npm run check:content  # content checks only, a few seconds
```

The Arabic site is served at `/` and the English site at `/en/`.

## Layout

- `content/lessons/ar`, `content/lessons/en`: one MDX file per lesson, same file names in both languages.
- `src/data`: the roadmap, datasets, quizzes, plugin guide and ICA game data.
- `src/i18n`: interface text in both languages.
- `src/components`, `src/layouts`, `src/pages`: Astro templates.
- `public/scripts`: the small scripts every page loads.
- `scripts`: build checks (`check-content.mjs`, `check-budget.mjs`) and converters.
- `tools`: MATLAB and Python scripts that produce the lesson figures and the ICA game images.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the lesson format and code style.

## Licence

- Code, including the code blocks in lessons: MIT, see [LICENSE](LICENSE).
- Lesson text, site text and original figures: CC BY-NC-SA 4.0, see [LICENSE-CONTENT.md](LICENSE-CONTENT.md), which also lists the exceptions (dataset figures, fonts, icons).
- This site is not affiliated with EEGLAB or SCCN.
