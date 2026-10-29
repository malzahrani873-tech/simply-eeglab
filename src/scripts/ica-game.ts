// ICA component game (rounds of 10 by level) and the component of the day. interactives_spec §5 and §12.
import { KEYS, read, write, storageOk } from './progress';

type Item = { id: string; src: string; w: number; h: number; level: number; answer: string; iclabel: Record<string, number>; hint: string | null; note: string; alt: string };
const root = document.getElementById('ica');
if (root) {
  const S: Record<string, any> = JSON.parse(root.dataset.s!);
  const NAMES: Record<string, string> = JSON.parse(root.dataset.names!);
  const PANELS: Record<string, string> = JSON.parse(root.dataset.panels!);
  const lang = root.dataset.lang!;
  const can = storageOk();
  const $ = <T extends HTMLElement = HTMLElement>(sel: string, el: ParentNode = root) => el.querySelector<T>(sel)!;
  const fill = (s: string, v: Record<string, string | number>) => s.replace(/\{(\w+)\}/g, (_, k) => String(v[k] ?? ''));
  const icon = (ok: boolean) => (document.getElementById(ok ? 'ic-ok' : 'ic-bad') as HTMLTemplateElement).content.cloneNode(true);
  const plural = (n: number) => { const f = new Intl.PluralRules(lang).select(n); return f === 'two' ? S.streakTwo : f === 'few' ? S.streakFew : S.streak; };
  root.hidden = false;

  // Feedback: result line, ICLabel bars, and the explanation layers that exist for this item.
  function feedback(box: HTMLElement, it: Item, ok: boolean, pick: string | null, sig: Record<string, string>, conf: Record<string, string>) {
    box.replaceChildren();
    const head = document.createElement('p');
    head.className = 'gres ' + (ok ? 'ok' : 'bad');
    head.append(icon(ok), document.createTextNode(ok ? S.correct : fill(S.wrong, { category: NAMES[it.answer] })));
    const bars = document.createElement('ul');
    bars.className = 'bars';
    for (const [c, p] of Object.entries(it.iclabel).sort((a, b) => b[1] - a[1])) {
      const li = document.createElement('li');
      li.innerHTML = `<span class="bn"></span><span class="bt"><i style="width:${Math.round(p * 100)}%"></i></span><span class="bp">${Math.round(p * 100)}%</span>`;
      li.firstElementChild!.textContent = NAMES[c];
      bars.append(li);
    }
    box.append(head, bars);
    for (const s of [sig[it.answer], it.note, !ok && pick ? conf[`${pick}>${it.answer}`] ?? sig[pick] : '']) {
      if (!s) continue;
      const p = document.createElement('p'); p.textContent = s; box.append(p);
    }
  }

  // ---------- rounds ----------
  let data: { dataVersion: string; items: Item[]; signature: Record<string, string>; confusions: Record<string, string> } | null = null;
  const RKEY = 'simplyeeglab:icaround.v1';
  type Round = { v: 1; data: string; level: number; order: string[]; i: number; answers: { id: string; pick: string; ok: boolean; hint: boolean }[]; state: 'question' | 'feedback' };
  let r: Round | null = null;
  let hintUsed = false;
  const game = $('#game');
  const btns = [...game.querySelectorAll<HTMLButtonElement>('[data-btns] .ab')];
  const img = $<HTMLImageElement>('[data-img]', game);
  const save = () => { try { r ? sessionStorage.setItem(RKEY, JSON.stringify(r)) : sessionStorage.removeItem(RKEY); } catch {} };
  const byId = (id: string) => data!.items.find((x) => x.id === id)!;
  const levels = () => [...new Set(data!.items.map((x) => x.level))].sort();
  const state = () => read<any>(KEYS.icagame) ?? { v: 1, seen: [], best: {}, rounds: 0 };

  function newRound(level: number) {
    const pool = data!.items.filter((x) => x.level === level);
    const seen = new Set<string>(state().seen);
    const fresh = pool.filter((x) => !seen.has(x.id));
    const src = fresh.length >= Math.min(10, pool.length) ? fresh : pool;
    $('[data-note]', game).textContent = src === pool && fresh.length < Math.min(10, pool.length) ? S.review : '';
    const order = [...src].sort(() => Math.random() - 0.5).slice(0, 10).map((x) => x.id);
    r = { v: 1, data: data!.dataVersion, level, order, i: 0, answers: [], state: 'question' };
    save();
    show();
  }

  function show() {
    const q = $('[data-q]', game), sum = $('[data-sum]', game);
    renderLevels();
    if (!r) return;
    if (r.i >= r.order.length) return summary();
    q.hidden = false; sum.hidden = true;
    const it = byId(r.order[r.i]);
    const daily = r.level < 3;
    btns.forEach((b, k) => { b.hidden = daily && b.dataset.c === 'other'; b.disabled = false; b.className = 'ab'; b.querySelector('.k')!.textContent = String(k + 1); });
    $('[data-prog]', game).textContent = fill(S.progress, { n: r.i + 1, total: r.order.length });
    $('[data-score]', game).textContent = fill(S.score, { n: r.answers.filter((a) => a.ok).length });
    $('[data-pfill]', game).style.width = `${(r.i / r.order.length) * 100}%`;
    $('[data-sign]', game).hidden = !(r.i === 0 && state().rounds === 0);
    $('[data-ierr]', game).hidden = true;
    img.hidden = false;
    img.src = it.src; img.width = it.w; img.height = it.h; img.alt = it.alt;
    const next = r.order[r.i + 1];
    if (next) new Image().src = byId(next).src;
    hintUsed = false;
    $('[data-hint]', game).hidden = !it.hint;
    $('[data-fb]', game).replaceChildren();
    $('[data-next]', game).hidden = true;
    if (r.state === 'feedback') { const a = r.answers[r.answers.length - 1]; reveal(it, a.pick, false); }
  }

  function answer(pick: string) {
    if (!r || r.state !== 'question') return;
    const it = byId(r.order[r.i]);
    const ok = pick === it.answer;
    r.answers.push({ id: it.id, pick, ok, hint: hintUsed });
    r.state = 'feedback';
    save();
    if (can) { const s = state(); if (!s.seen.includes(it.id)) s.seen.push(it.id); write(KEYS.icagame, s); }
    reveal(it, pick, true);
  }

  function reveal(it: Item, pick: string, focus: boolean) {
    btns.forEach((b) => {
      b.disabled = true;
      if (b.dataset.c === it.answer) b.classList.add('is-ans');
      else if (b.dataset.c === pick) b.classList.add('is-miss');
    });
    $('[data-hint]', game).hidden = true;
    const fb = $('[data-fb]', game);
    feedback(fb, it, pick === it.answer, pick, data!.signature, data!.confusions);
    const nx = $('[data-next]', game);
    nx.hidden = false;
    if (focus) fb.focus();
  }

  function summary() {
    $('[data-q]', game).hidden = true;
    const sum = $('[data-sum]', game);
    sum.hidden = false;
    const n = r!.answers.filter((a) => a.ok).length, total = r!.order.length;
    $('[data-sum-score]', game).textContent = fill(S.sumScore, { n, total });
    let best = n;
    if (can) {
      const s = state();
      best = Math.max(n, s.best[r!.level] ?? 0);
      s.best[r!.level] = best; s.rounds = (s.rounds ?? 0) + 1;
      write(KEYS.icagame, s);
    }
    $('[data-sum-best]', game).textContent = fill(S.best, { n: best });
    const hints = r!.answers.filter((a) => a.hint).length;
    $('[data-sum-hints]', game).hidden = !hints;
    $('[data-sum-hints]', game).textContent = fill(S.hints, { n: hints });
    const weak = [...new Set(r!.answers.filter((a) => !a.ok).map((a) => byId(a.id).answer))];
    const wbox = $('[data-sum-weak]', game);
    wbox.hidden = !weak.length;
    $('ul', wbox).replaceChildren(...weak.map((c) => { const li = document.createElement('li'); li.textContent = NAMES[c]; return li; }));
    $('[data-copy]', game).onclick = async () => {
      const text = fill(S.share, { level: r!.level, rounds: state().rounds, score: n, total });
      try { await navigator.clipboard.writeText(text); $('[data-copy-status]', game).textContent = S.copied; } catch { $('[data-copy-status]', game).textContent = text; }
    };
    sum.focus();
  }

  function renderLevels() {
    const nav = $('[data-levels]', game);
    const ls = levels();
    nav.hidden = ls.length < 2;
    nav.replaceChildren(...ls.map((l) => {
      const b = document.createElement('button');
      b.type = 'button'; b.textContent = fill(root!.querySelector('[data-levels]')!.getAttribute('aria-label')! + '{n}', { n: l }).trim();
      b.setAttribute('aria-pressed', String(r?.level === l));
      b.onclick = () => newRound(l);
      return b;
    }));
  }

  btns.forEach((b) => b.addEventListener('click', () => answer(b.dataset.c!)));
  $('[data-next]', game).addEventListener('click', () => { r!.i++; r!.state = 'question'; save(); show(); (r!.i < r!.order.length ? btns.find((b) => !b.hidden) : null)?.focus(); });
  $('[data-new]', game).addEventListener('click', () => newRound(r?.level ?? levels()[0]));
  $('[data-hint]', game).addEventListener('click', () => {
    const it = byId(r!.order[r!.i]); hintUsed = true;
    const p = document.createElement('p'); p.className = 'ghint'; p.textContent = fill(S.lookAt, { panel: PANELS[it.hint!] ?? it.hint! });
    $('[data-fb]', game).replaceChildren(p);
  });
  $('[data-skip]', game).addEventListener('click', () => { r!.order.splice(r!.i, 1); save(); show(); });
  img.addEventListener('error', () => { if (img.getAttribute('src')) { img.hidden = true; $('[data-ierr]', game).hidden = false; } });
  game.addEventListener('keydown', (e) => {
    if (e.target instanceof HTMLInputElement) return;
    const k = Number(e.key);
    if (k >= 1 && k <= 7) { const b = btns.filter((x) => !x.hidden)[k - 1]; if (b && !b.disabled) { e.preventDefault(); b.click(); } }
    else if (e.key === 'Enter' && r?.state === 'feedback' && !(e.target instanceof HTMLButtonElement)) { e.preventDefault(); $('[data-next]', game).click(); }
  });

  async function start() {
    try {
      data = await (await fetch(root!.dataset.src!)).json();
    } catch {
      const p = $('[data-note]', game);
      p.textContent = S.loadError;
      $('[data-q]', game).hidden = true;
      return;
    }
    let saved: Round | null = null;
    try { saved = JSON.parse(sessionStorage.getItem(RKEY) ?? 'null'); } catch {}
    if (saved?.v === 1 && saved.data === data!.dataVersion && saved.order.every((id) => data!.items.some((x) => x.id === id))) {
      r = saved; $('[data-note]', game).textContent = S.resumed; show();
    } else newRound(levels()[0]);
  }
  start();
  addEventListener('progress-reset', () => { try { sessionStorage.removeItem(RKEY); } catch {} });

  // ---------- component of the day ----------
  // The component of the day is left out of the page while its list is empty.
  const daily = document.querySelector<HTMLElement>('#daily');
  if (daily) {
  const DAY = 86400000;
  const dayNo = () => Math.floor((Date.now() + 3 * 3600 * 1000) / DAY);
  const epoch = Math.floor((Date.parse(root.dataset.epoch! + 'T00:00:00Z')) / DAY);
  const N = Math.max(1, dayNo() - epoch + 1);
  $('[data-d-num]', daily).textContent = fill(S.dNumber, { n: N });
  const dBtns = [...daily.querySelectorAll<HTMLButtonElement>('[data-d-btns] .ab')];
  type Daily = { v: 1; last: number; result: number; streak: number; best: number; played: number; solved: number; attempts?: string[]; chain?: boolean };
  const dget = (): Daily => {
    const d = read<Daily>(KEYS.daily) ?? { v: 1, last: 0, result: 0, streak: 0, best: 0, played: 0, solved: 0 };
    if (d.last > N) { d.last = 0; d.attempts = []; } // device clock went back: a new day, no streak
    return d;
  };
  let mem: Daily = dget();
  const dstore = (d: Daily) => { mem = d; if (can) write(KEYS.daily, d); };
  const dState = () => (can ? dget() : mem);
  $('[data-d-nostore]', daily).hidden = can;

  function streakLine() {
    const s = dState().streak;
    $('[data-d-streak]', daily).textContent = s ? fill(plural(s), { n: s }) : '';
  }

  async function loadDaily() {
    let it: any;
    try {
      // Find today's position: the list length is the number of files; the build writes one per index.
      const idx = await fetch(`${root!.dataset.daily}count.json`).then((x) => x.json()).then((c) => (N - 1) % c.n);
      it = await fetch(`${root!.dataset.daily}${idx}.${lang}.json`).then((x) => x.json());
    } catch {
      $('[data-d-fb]', daily).textContent = S.dLoadError;
      return;
    }
    const im = $<HTMLImageElement>('[data-d-img]', daily);
    im.src = it.src; im.width = it.w; im.height = it.h; im.alt = it.alt ?? '';
    streakLine();
    const d = dState();
    const today = d.last === N ? d.attempts ?? [] : [];
    // Up to three tries a day; a right answer ends the day early.
    const finished = () => today.includes(it.answer) || today.length >= 3;
    const paint = () => {
      dBtns.forEach((b) => {
        const c = b.dataset.c!;
        b.disabled = finished() || today.includes(c);
        b.classList.toggle('is-miss', today.includes(c) && c !== it.answer);
        b.classList.toggle('is-ans', finished() && c === it.answer);
      });
    };
    const end = (focus: boolean) => {
      const solved = today.includes(it.answer);
      feedback($('[data-d-fb]', daily), it, solved, today.find((c) => c !== it.answer) ?? null, it.signature, it.confusions);
      $('[data-d-end]', daily).hidden = false;
      const hours = Math.max(1, Math.ceil(((dayNo() + 1) * DAY - (Date.now() + 3 * 3600 * 1000)) / 3600000));
      $('[data-d-next]', daily).textContent = fill(S.dNext, { n: hours });
      $<HTMLButtonElement>('[data-d-copy]', daily).onclick = async () => {
        const marks = today.map((c) => (c === it.answer ? '✓' : '✗')).join(' ');
        const lines = [fill(S.dLine1, { n: N }), `${marks}  (${solved ? S.dTries[today.length - 1] : S.dNone})`];
        if (can && dState().streak) lines.push(fill(S.dStreak, { n: dState().streak }));
        lines.push(fill(S.dLink, { url: root!.dataset.url! }));
        const text = lines.join('\n');
        try { await navigator.clipboard.writeText(text); $('[data-d-next]', daily).textContent = S.copied; } catch { $('[data-d-next]', daily).textContent = text; }
      };
      if (focus) $('[data-d-fb]', daily).focus?.();
    };
    paint();
    if (finished()) end(false);
    dBtns.forEach((b) => b.addEventListener('click', () => {
      if (finished()) return;
      const c = b.dataset.c!;
      today.push(c);
      const cur = dState();
      const solved = c === it.answer;
      const done = solved || today.length >= 3;
      const next: Daily = { ...cur, attempts: today };
      // On the first try of the day, remember whether yesterday was solved: the streak continues only then.
      if (cur.last !== N) { next.played = cur.played + 1; next.chain = cur.last === N - 1 && cur.result > 0; next.result = 0; }
      if (done) {
        next.result = solved ? today.length : 0;
        if (solved) { next.solved = cur.solved + 1; next.streak = next.chain ? cur.streak + 1 : 1; }
        else next.streak = 0;
        next.best = Math.max(cur.best, next.streak);
      }
      next.last = N;
      dstore(next);
      paint();
      if (done) { streakLine(); end(true); }
      else {
        const p = document.createElement('p'); p.className = 'ghint';
        p.textContent = today.length === 1 && it.hint ? fill(S.lookAt, { panel: PANELS[it.hint] ?? it.hint }) : (it.confusions?.[`${c}>${it.answer}`] || it.signature?.[c] || fill(S.dNot, { category: NAMES[c] ?? c }));
        $('[data-d-fb]', daily).replaceChildren(icon(false), p);
      }
    }));
  }
  loadDaily();
  }
}

// "Enlarge": the current component image at full size in a dialog; it scrolls, and pinch-zooms on touch screens.
{
  const btn = document.querySelector<HTMLButtonElement>('[data-zoom]');
  const dlg = document.querySelector<HTMLDialogElement>('[data-zoomd]');
  const src = document.querySelector<HTMLImageElement>('[data-img]');
  if (btn && dlg && src && dlg.showModal) {
    btn.hidden = false;
    const big = dlg.querySelector('img')!;
    btn.addEventListener('click', () => { big.src = src.currentSrc || src.src; big.alt = src.alt; dlg.showModal(); });
    dlg.querySelector('[data-zclose]')!.addEventListener('click', () => dlg.close());
    dlg.addEventListener('click', (e) => { if (e.target === dlg) dlg.close(); });
  }
}
