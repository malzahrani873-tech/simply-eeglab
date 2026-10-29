// Content checks before the build (tech_spec §4.6, §5.2, §23, §27.2, §28.2, §29.6).
// Reads content/lessons/ and src/data/ only. Any error fails the build; warnings are printed.
// Usage: node scripts/check-content.mjs
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { load as loadYaml } from 'js-yaml';
import { loadRoadmap, loadDatasets } from '../src/lib/roadmap.mjs';

const production = process.env.CONTENT_MODE === 'production' || (process.env.CF_PAGES === '1' && process.env.CF_PAGES_BRANCH === 'main');
// Written exception list for figures still to come (see figures-pending.txt): "<lesson file> <count>" per line.
const pendingFigures = new Map(existsSync('figures-pending.txt') ? readFileSync('figures-pending.txt', 'utf8').split('\n').filter((l) => l.trim() && !l.startsWith('#')).map((l) => { const [f, n] = l.trim().split(/\s+/); return [f, Number(n)]; }) : []);
// Lessons where a demo's default setting is not the lesson's pipeline setting (interactives_spec §1.6a).
const PIPELINE_NOTE = { FilterDemo: ['filtering'], RerefDemo: ['rereferencing'] };
const slugOf = (f) => f.split('/').pop().replace(/^\d\d-\d\d-/, '').replace(/\.mdx$/, '');
const errors = [];
const warnings = [];
const err = (file, msg) => errors.push(`${file}: ${msg}`);
const warn = (file, msg) => warnings.push(`${file}: ${msg}`);

const roadmap = loadRoadmap();
const datasets = new Map(loadDatasets().map((d) => [d.code, d]));
const OFFICIAL = /^https:\/\/([a-z0-9-]+\.)?(eeglab\.org|sccn\.ucsd\.edu|mne\.tools|fieldtriptoolbox\.org)\/|^https:\/\/github\.com\/(sccn|ucdavis\/erplab)\b/;
const REFERENCE_LIMIT_EXCEPTIONS = { 'install-eeglab': 6, 'run-ica': 5 };
const REFERENCE_ORDER_EXCEPTIONS = new Set(['electrode-10-20']);
const CALLOUT_TYPES = new Set(['note', 'warning', 'expert', 'experience']);

// ---------- roadmap and next chain (§5.2) ----------
{
  const f = 'src/data/roadmap.yaml';
  const seen = new Set();
  for (const n of roadmap.nodes) {
    if (seen.has(n.id)) err(f, `معرّف مكرّر: ${n.id}`);
    seen.add(n.id);
    for (const k of ['minutes', 'level', 'titleEn', 'title']) if (n[k] === undefined) err(f, `العقدة ${n.id} ينقصها ${k}`);
    if (n.next && !roadmap.byId.has(n.next)) err(f, `next في ${n.id} يشير إلى ${n.next} غير الموجود`);
  }
  const cores = roadmap.nodes.filter((n) => n.level === 'core').map((n) => n.id);
  const chain = [];
  for (let id = cores[0], guard = 0; id && guard < 500; guard++) {
    const n = roadmap.byId.get(id);
    if (n.level === 'core') chain.push(id);
    id = n.next;
  }
  if (chain.join() !== cores.join()) err(f, `سلسلة next من أول درس أساسي لا تمرّ على الدروس الأساسية (${cores.length}) بترتيبها`);
  for (const n of roadmap.nodes) {
    const visited = new Set();
    let id = n.id;
    while (id && !visited.has(id)) { visited.add(id); id = roadmap.byId.get(id)?.next; }
    if (id) err(f, `حلقة في سلسلة next تبدأ من ${n.id}`);
  }
  for (const n of roadmap.nodes) if (n.next !== null && n.explicitNext) warn(f, `استثناء next في ${n.id}`);
}

// ---------- progress slots (§24.2) ----------
{
  const f = 'src/data/progress-slots.lock';
  const slots = readFileSync(f, 'utf8').split('\n').map((s) => s.trim()).filter((s) => s && !s.startsWith('#'));
  if (new Set(slots).size !== slots.length) err(f, 'خانة مكرّرة');
  for (const n of roadmap.nodes) if (!slots.includes(n.id)) err(f, `العقدة ${n.id} بلا خانة تقدّم (أضفها في آخر الملف)`);
}

// ---------- lessons ----------
const parse = (file) => {
  const src = readFileSync(file, 'utf8');
  const m = src.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!m) { err(file, 'لا يوجد frontmatter'); return null; }
  try { return { fm: loadYaml(m[1]), body: m[2] }; } catch (e) { err(file, `frontmatter غير صالح: ${e.message.split('\n')[0]}`); return null; }
};
const lessons = { ar: new Map(), en: new Map() };
for (const lang of ['ar', 'en']) {
  for (const name of readdirSync(`content/lessons/${lang}`).filter((x) => x.endsWith('.mdx'))) {
    const file = `content/lessons/${lang}/${name}`;
    const slug = name.replace(/^\d\d-\d\d-/, '').replace(/\.mdx$/, '');
    const p = parse(file);
    if (p) lessons[lang].set(slug, { file, ...p });
  }
}

const lineOf = (body, needle) => body.slice(0, Math.max(0, body.indexOf(needle))).split('\n').length;
const imageSpecs = [];
for (const lang of ['ar', 'en']) {
  for (const [slug, { file, fm, body }] of lessons[lang]) {
    const node = roadmap.byId.get(slug);
    if (!node) { err(file, `الدرس ${slug} ليس له عقدة في roadmap.yaml`); continue; }
    if ('minutes' in fm || 'next' in fm) err(file, 'minutes و next تُكتب في roadmap.yaml لا في الدرس');
    if (fm.station !== node.station) err(file, `station ${fm.station} لا يطابق العقدة (${node.station})`);
    if (fm.level !== node.level) err(file, `level ${fm.level} لا يطابق العقدة (${node.level})`);
    for (const p of fm.prerequisites ?? []) {
      if (!roadmap.byId.has(p)) err(file, `المتطلب ${p} غير موجود في الخريطة`);
      else if (node.level === 'core' && roadmap.byId.get(p).level !== 'core' && !node.prerequisitesException) err(file, `درس أساسي متطلبه ${p} غير أساسي`);
    }
    // starting point (§4.3)
    const ds = fm.datasets ?? [];
    for (const d of ds) if (!datasets.has(d)) err(file, `الداتاست ${d} غير موجودة في datasets.yaml`);
    if (ds.length && !fm.startingPoint) err(file, 'datasets غير فارغ و startingPoint غائب');
    if (fm.startingPoint) {
      if (!ds.includes(fm.startingPoint.dataset)) err(file, `startingPoint.dataset (${fm.startingPoint.dataset}) ليس في datasets`);
      for (const a of fm.startingPoint.applied ?? []) if (!roadmap.byId.has(a)) err(file, `applied فيه ${a} غير الموجود`);
    }
    // ImageSpec in approved lessons
    for (const m of body.matchAll(/<ImageSpec(\s[^>]*)?>/g)) {
      const optional = /\boptional\b/.test(m[1] ?? '');
      if (!optional) imageSpecs.push(`${file}:${lineOf(body, m[0])}`);
      if (fm.status === 'approved' && !optional && !pendingFigures.has(file)) err(file, `سطر ${lineOf(body, m[0])}: <ImageSpec> إلزامي في درس معتمد`);
    }
    // figures and their sources
    for (const m of body.matchAll(/<Figure\b([^>]*)\/?>/g)) {
      const src = m[1].match(/source="([^"]+)"/)?.[1];
      if (!src) err(file, `سطر ${lineOf(body, m[0])}: <Figure> بلا source`);
      else if (/^D\d$/.test(src) && !ds.includes(src)) err(file, `سطر ${lineOf(body, m[0])}: source ${src} ليس في datasets الدرس`);
    }
    // a frontmatter key inside code means a YAML indentation slip cut the script short
    const fmKey = /^\s*(title|description|station|order|level|status|prerequisites|objectives|datasets|startingPoint|dataset|file|applied|script|interactive|references|eeglabVersion|updated):(\s|$)/m;
    if (fm.startingPoint?.script && fmKey.test(fm.startingPoint.script)) err(file, 'startingPoint.script فيه سطر يبدأ بمفتاح frontmatter: غالباً خطأ مسافة بادئة في YAML');
    for (const m of body.matchAll(/^(`{3,}|~{3,})[^\n]*\n([\s\S]*?)^\1\s*$/gm)) if (fmKey.test(m[2])) err(file, `سطر ${lineOf(body, m[0])}: كتلة كود فيها سطر يبدأ بمفتاح frontmatter`);
    // the interactive list matches the demos used in the body, both ways
    const used = new Set([...body.matchAll(/<(FilterDemo|RerefDemo|EpochRejectDemo|IcaGameTeaser)\b/g)].map((m) => m[1]));
    const listed = new Set(fm.interactive ?? []);
    for (const x of used) if (!listed.has(x)) err(file, `<${x}> مستعمل في النص وليس في interactive`);
    for (const x of listed) if (!used.has(x)) err(file, `${x} في interactive وغير مستعمل في النص`);
    // forbidden tags (§4.4, §4.5)
    if (/<StationQuiz\b/.test(body)) err(file, '<StationQuiz> مكانه صفحة المحطة لا الدرس');
    if (/^import\s/m.test(body.replace(/^(`{3,}|~{3,})[^\n]*\n[\s\S]*?^\1\s*$/gm, ''))) err(file, 'import غير مسموح في نص الدرس');
    if (/<Term\b/.test(body)) err(file, '<Term> يضيفه البناء، لا يكتبه الكاتب');
    for (const m of body.matchAll(/<MenuPath>([\s\S]*?)<\/MenuPath>/g)) if (m[1].includes('←')) err(file, `سطر ${lineOf(body, m[0])}: سهم ← داخل <MenuPath>، استخدم >`);
    // callouts (§29.6)
    for (const m of body.matchAll(/<Callout\b([^>]*)>\s*([\s\S]*?)<\/Callout>/g)) {
      const type = m[1].match(/type="([^"]+)"/)?.[1];
      const hasTitle = /\btitle="/.test(m[1]);
      const at = `سطر ${lineOf(body, m[0])}`;
      if (!CALLOUT_TYPES.has(type)) warn(file, `${at}: نوع Callout غير معروف "${type}" (يُعرض كملاحظة)`);
      if (hasTitle && type !== 'note') err(file, `${at}: title مسموح لـ note فقط`);
      if ((type === 'note' || !CALLOUT_TYPES.has(type)) && !hasTitle && !/^\*\*/.test(m[2].trim())) warn(file, `${at}: ملاحظة بلا title ولا عبارة عريضة في أولها`);
    }
    // references (§28.2)
    const refs = fm.references ?? [];
    if (!refs.some((r) => OFFICIAL.test(r.url))) err(file, 'لا يوجد مرجع رسمي واحد على الأقل');
    for (const r of refs) {
      const video = r.type === 'video' || /youtube\.com|youtu\.be/.test(r.url);
      if (!/^https:\/\//.test(r.url)) err(file, `رابط مرجع ليس https: ${r.url}`);
      if (r.type === 'video' && !/youtube\.com|youtu\.be/.test(r.url)) err(file, `فيديو من غير YouTube: ${r.url}`);
      if (video && !/^\d{1,2}:\d{2}(:\d{2})?$/.test(r.duration ?? '')) err(file, `فيديو بلا duration صحيح: ${r.title}`);
    }
    const limit = REFERENCE_LIMIT_EXCEPTIONS[slug] ?? 4;
    if (refs.length > limit) warn(file, `${refs.length} مراجع (الحد ${limit})`);
    if (!REFERENCE_ORDER_EXCEPTIONS.has(slug)) {
      const firstNonOfficial = refs.findIndex((r) => !OFFICIAL.test(r.url));
      if (firstNonOfficial >= 0 && refs.slice(firstNonOfficial).some((r) => OFFICIAL.test(r.url))) warn(file, 'ترتيب المراجع: الرسمي أولاً');
    }
    // A demo whose default differs from this lesson's pipeline must say the pipeline value (interactives_spec §1.6a).
    for (const [demo, where] of Object.entries(PIPELINE_NOTE)) {
      if (!where.includes(slugOf(file))) continue;
      for (const m of body.matchAll(new RegExp(`<${demo}\\b([^>]*)>`, 'g'))) if (!/\bpipeline="[^"]+"/.test(m[1])) err(file, `سطر ${lineOf(body, m[0])}: <${demo}> بلا pipeline، وافتراضيه يختلف عن مسار الدرس`);
    }
    // Methods (§23.1)
    const methods = body.match(/<Methods>\s*([\s\S]*?)\s*<\/Methods>/)?.[1];
    if (methods) {
      if (/<[a-zA-Z]|\*\*|`/.test(methods)) err(file, 'Methods فيه وسم أو Markdown');
      // [value] slots are part of the Methods template (decision ق-36): the reader fills them in.
      if (fm.status === 'approved' && methods.includes('[')) warn(file, 'Methods فيه خانات [قيمة] يملؤها القارئ');
    } else if (fm.status === 'approved' && fm.station >= 2 && /```matlab/.test(body)) warn(file, 'درس معتمد بخطوة معالجة بلا <Methods>');
    // BeforeAfter (§23.2)
    for (const m of body.matchAll(/<BeforeAfter\b[^>]*>([\s\S]*?)<\/BeforeAfter>/g)) {
      const kids = m[1].match(/<(Figure|ImageSpec)\b/g) ?? [];
      if (kids.length !== 2) err(file, `سطر ${lineOf(body, m[0])}: BeforeAfter يحتاج صورتين بالضبط`);
      const sources = [...m[1].matchAll(/source="([^"]+)"/g)].map((x) => x[1]);
      if (new Set(sources).size > 1) err(file, `سطر ${lineOf(body, m[0])}: source مختلف بين صورتي BeforeAfter`);
    }
    if (fm.eeglabVersion !== '2026.1') warn(file, `eeglabVersion ${fm.eeglabVersion} أقدم من إصدار المشروع`);
  }
}

// both languages (§17.2)
const same = (a, b) => JSON.stringify(a ?? null) === JSON.stringify(b ?? null);
for (const [slug, ar] of lessons.ar) {
  const en = lessons.en.get(slug);
  if (!en) { err(ar.file, 'لا توجد نسخة إنجليزية'); continue; }
  for (const k of ['station', 'level', 'prerequisites', 'datasets']) if (!same(ar.fm[k], en.fm[k])) err(en.file, `${k} يختلف عن العربية`);
  const sp = (x) => x && { dataset: x.dataset, file: x.file, applied: x.applied };
  if (!same(sp(ar.fm.startingPoint), sp(en.fm.startingPoint))) err(en.file, 'startingPoint يختلف عن العربية');
  if (en.fm.status === 'approved' && ar.fm.status !== 'approved') err(en.file, 'الإنجليزية معتمدة والعربية غير معتمدة');
  const norm = (s) => s?.replace(/\s+/g, ' ').trim();
  const ma = norm(ar.body.match(/<Methods>([\s\S]*?)<\/Methods>/)?.[1]), me = norm(en.body.match(/<Methods>([\s\S]*?)<\/Methods>/)?.[1]);
  if (ma !== me) err(en.file, 'نص Methods يختلف بين اللغتين');
}
for (const [slug, en] of lessons.en) if (!lessons.ar.has(slug)) err(en.file, 'لا توجد نسخة عربية');

// ---------- station quizzes (§27.2) ----------
const QTYPES = new Set(['single', 'multiple', 'order', 'image']);
const quizzes = {};
for (const name of readdirSync('src/data/quizzes').filter((x) => x.endsWith('.json'))) {
  const f = `src/data/quizzes/${name}`;
  const [, nn, lang] = name.match(/^(\d\d)\.(ar|en)\.json$/) ?? [];
  if (!nn) { err(f, 'اسم الملف ليس NN.lang.json'); continue; }
  let q;
  try { q = JSON.parse(readFileSync(f, 'utf8')); } catch (e) { err(f, `JSON غير صالح: ${e.message}`); continue; }
  quizzes[name] = q;
  if (q.v !== 1) err(f, 'v ليس 1');
  if (q.station !== Number(nn) || q.lang !== lang) err(f, 'station أو lang لا يطابقان اسم الملف');
  if (!(q.passPercent >= 50 && q.passPercent <= 100)) err(f, 'passPercent بين 50 و 100');
  const ids = new Set();
  for (const x of q.questions ?? []) {
    const at = `${x.id}`;
    if (!/^s\d\d-q\d\d$/.test(x.id ?? '')) err(f, `${at}: id بصيغة sNN-qMM`);
    if (ids.has(x.id)) err(f, `${at}: id مكرّر`);
    ids.add(x.id);
    if (!QTYPES.has(x.type)) err(f, `${at}: نوع غير معروف ${x.type}`);
    const node = roadmap.byId.get(x.lesson);
    if (!node || node.station !== q.station) err(f, `${at}: الدرس ${x.lesson} ليس في نفس المحطة`);
    const lesson = lessons[lang].get(x.lesson);
    if (lesson && !(x.objective >= 1 && x.objective <= (lesson.fm.objectives ?? []).length)) err(f, `${at}: objective ${x.objective} أكبر من أهداف الدرس`);
    for (const k of ['prompt', 'explanation']) if (!x[k]?.trim()) err(f, `${at}: ${k} فارغ`);
    const opts = (x.options ?? []).map((o) => o.id);
    if (new Set(opts).size !== opts.length) err(f, `${at}: معرّف خيار مكرّر`);
    const ans = x.answer ?? [];
    if (!ans.length || ans.some((a) => !opts.includes(a))) err(f, `${at}: answer فارغ أو فيه خيار غير موجود`);
    if ((x.type === 'single' || x.type === 'image') && ans.length !== 1) err(f, `${at}: ${x.type} بإجابة واحدة`);
    if (x.type === 'multiple' && ans.length < 2) err(f, `${at}: multiple بإجابتين أو أكثر`);
    if (x.type === 'order' && (ans.length !== opts.length || new Set(ans).size !== opts.length)) err(f, `${at}: order يحتوي كل الخيارات مرة واحدة`);
    if (x.image) {
      if (!x.image.src?.startsWith(`/quiz/${nn}/`)) err(f, `${at}: image.src يبدأ بـ /quiz/${nn}/`);
      if (!['pending', 'draft', 'ready'].includes(x.image.status)) err(f, `${at}: image.status غير معروف`);
      if (!x.image.alt?.trim()) err(f, `${at}: image.alt فارغ`);
      if (x.image.status === 'ready' && !existsSync(`public${x.image.src}`)) err(f, `${at}: ملف الصورة غير موجود`);
    } else if (x.type === 'image') err(f, `${at}: سؤال image بلا صورة`);
  }
}
for (const [name, q] of Object.entries(quizzes)) {
  if (q.lang !== 'ar') continue;
  const enName = name.replace('.ar.', '.en.');
  const en = quizzes[enName];
  if (!en) { err(`src/data/quizzes/${name}`, 'لا يوجد ملف إنجليزي مقابل'); continue; }
  const neutral = (x) => JSON.stringify({ id: x.id, type: x.type, lesson: x.lesson, objective: x.objective, answer: x.answer, options: x.options.map((o) => o.id), image: x.image && { src: x.image.src, w: x.image.w, h: x.image.h, status: x.image.status } });
  if (q.questions.map(neutral).join() !== en.questions.map(neutral).join()) err(`src/data/quizzes/${enName}`, 'الأسئلة أو حقولها المحايدة تختلف عن العربية');
}

// ---------- plugins guide (§23.9) ----------
// ---------- glossary ----------
{
  const f = 'src/data/glossary.json';
  const seen = new Set();
  for (const g of JSON.parse(readFileSync(f, 'utf8'))) {
    if (seen.has(g.id)) err(f, `معرّف مكرر ${g.id}`);
    seen.add(g.id);
    if (!g.def?.ar?.trim() || !g.def?.en?.trim()) err(f, `${g.id}: تعريف فارغ`);
    if (!['ع', 'إ', 'ع+إ'].includes(g.decision)) err(f, `${g.id}: قرار غير معروف "${g.decision}"`);
  }
}

if (existsSync('src/data/plugins.json')) {
  const f = 'src/data/plugins.json';
  const p = JSON.parse(readFileSync(f, 'utf8'));
  const names = new Set();
  for (const g of p.groups) for (const it of g.items) {
    if (names.has(it.name)) err(f, `اسم مكرّر: ${it.name}`);
    names.add(it.name);
    if (it.url && !/^https:\/\//.test(it.url)) err(f, `${it.name}: الرابط ليس https`);
    if (!it.text.ar?.trim() || !it.text.en?.trim()) err(f, `${it.name}: وصف فارغ`);
    for (const l of it.lessons) if (!roadmap.byId.has(l)) err(f, `${it.name}: الدرس ${l} غير موجود في الخريطة`);
  }
}

// ---------- ICA game and daily list (§23.6) ----------
for (const [f, daily] of [['src/data/ica-game.items.json', false], ['src/data/ica-daily.items.json', true]]) {
  if (!existsSync(f)) continue;
  const items = JSON.parse(readFileSync(f, 'utf8')).items ?? [];
  const ids = items.map((x) => x.id);
  if (new Set(ids).size !== ids.length) err(f, 'معرّف مكرّر');
  for (const it of items) {
    const name = String(it.img ?? '').split('/').pop();
    if (!existsSync(`assets-src/ica/${name}`)) err(f, `${it.id}: الصورة ${name} ليست في assets-src/ica/`);
    if (!daily) continue;
    if (it.answer === 'other') err(f, `${it.id}: فئة "أخرى" لا تدخل مكوّن اليوم`);
    if (Math.max(...Object.values(it.iclabel)) < 0.9) err(f, `${it.id}: أعلى احتمال ICLabel أقل من 0.9`);
    if (it.validation?.expert_agrees !== true) err(f, `${it.id}: لم يوافق عليه الخبير`);
  }
  if (daily) {
    const lock = existsSync('src/data/ica-daily.lock') ? readFileSync('src/data/ica-daily.lock', 'utf8').split('\n').filter(Boolean) : [];
    if (lock.some((id, i) => ids[i] !== id)) err(f, 'ترتيب القائمة تغيّر عن ica-daily.lock (يُضاف في الآخر فقط)');
  }
}

// ---------- release placeholders ----------
// Previews build with these open; a production build may not.
if (production) {
  for (const f of ['LICENSE', 'LICENSE-CONTENT.md']) if (readFileSync(f, 'utf8').includes('<OWNER_FULL_NAME>')) err(f, 'اسم صاحب الحقوق ما زال <OWNER_FULL_NAME>');
  for (const d of datasets.values()) if (d.dataUrl === 'TBD') err('src/data/datasets.yaml', `${d.code}: dataUrl ما زال TBD`);
  // Written exception (first release): listed lessons may go live with their required figures still
  // pending, shown as "image coming soon". The count per file may only go down.
  const count = {};
  for (const x of imageSpecs) { const f = x.replace(/:\d+$/, ''); count[f] = (count[f] ?? 0) + 1; }
  for (const [f, n] of Object.entries(count)) {
    if (!pendingFigures.has(f)) err(f, `${n} صورة مطلوبة لم تُصنع بعد (<ImageSpec>)`);
    else if (n > pendingFigures.get(f)) err(f, `${n} صورة معلّقة، والاستثناء يسمح بـ ${pendingFigures.get(f)} فقط`);
  }
}

// A production quiz drops questions whose image is not ready or whose lesson is not approved (src/lib/quiz.ts);
// a quiz left with fewer than 4 questions is held back until its questions return.
if (production) {
  for (const [name, q] of Object.entries(quizzes)) {
    const lang = name.endsWith('.en.json') ? 'en' : 'ar';
    const live = new Set(readdirSync(`content/lessons/${lang}`).filter((f) => /^status:\s*approved\s*$/m.test(readFileSync(`content/lessons/${lang}/${f}`, 'utf8'))).map((f) => f.replace(/^\d\d-\d\d-/, '').replace(/\.mdx$/, '')));
    const left = q.questions.filter((x) => (!x.image || x.image.status === 'ready') && live.has(x.lesson)).length;
    if (left < 4) warn(`src/data/quizzes/${name}`, `يبقى ${left} أسئلة في النشر (أقل من 4)، فيُحجب الاختبار`);
  }
}

// ---------- report ----------
console.log(`content checks: ${lessons.ar.size + lessons.en.size} lessons, ${Object.keys(quizzes).length} quiz files${production ? ' (production)' : ''}`);
if (imageSpecs.length) console.log(`  ${imageSpecs.length} required <ImageSpec> still waiting for figures`);
for (const w of warnings) console.log(`  warning  ${w}`);
for (const e of errors) console.error(`  error    ${e}`);
if (errors.length) {
  console.error(`\n${errors.length} content error(s). Fix them before building.`);
  process.exit(1);
}
