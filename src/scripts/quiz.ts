// Station quiz: check each question, then show the score and the lessons worth reviewing.
// Without JS every question keeps its "show the answer" fold.
import { markPassed, storageOk } from './progress';

const root = document.querySelector<HTMLElement>('#quiz');
if (root) {
  const L = root.dataset;
  const qs = [...root.querySelectorAll<HTMLFieldSetElement>('fieldset.qz')];
  const results = new Map<string, boolean>();
  const sum = root.querySelector<HTMLElement>('.qz-sum')!;
  const icon = (id: string) => (root.querySelector<HTMLTemplateElement>(`#qz-ic-${id}`)!.content.cloneNode(true));

  const items = (fs: HTMLElement) => [...fs.querySelectorAll<HTMLLIElement>('.ord > li')];
  function shuffle(fs: HTMLFieldSetElement) {
    const ol = fs.querySelector('.ord')!, ans = JSON.parse(fs.dataset.answer!);
    let li = items(fs);
    do {
      for (let i = li.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [li[i], li[j]] = [li[j], li[i]]; }
    } while (li.map((x) => x.dataset.id).join() === ans.join());
    li.forEach((x) => ol.append(x));
    syncOrder(fs);
  }
  function syncOrder(fs: HTMLElement) {
    const li = items(fs);
    li.forEach((x, i) => {
      x.querySelector<HTMLButtonElement>('[data-mv="-1"]')!.disabled = i === 0 || fs.classList.contains('checked');
      x.querySelector<HTMLButtonElement>('[data-mv="1"]')!.disabled = i === li.length - 1 || fs.classList.contains('checked');
    });
  }
  function chosen(fs: HTMLFieldSetElement): string[] {
    if (fs.dataset.type === 'order') return items(fs).map((x) => x.dataset.id!);
    return [...fs.querySelectorAll<HTMLInputElement>('input:checked')].map((x) => x.value);
  }
  function check(fs: HTMLFieldSetElement) {
    const fb = fs.querySelector<HTMLElement>('.qz-fb')!;
    const got = chosen(fs), ans: string[] = JSON.parse(fs.dataset.answer!);
    if (!got.length) { fb.textContent = L.lPick!; return; }
    const right = fs.dataset.type === 'order' ? got.join() === ans.join() : got.length === ans.length && got.every((g) => ans.includes(g));
    results.set(fs.id, right);
    fs.classList.add('checked', right ? 'right' : 'wrong');
    fs.querySelectorAll<HTMLInputElement>('input').forEach((x) => {
      x.disabled = true;
      x.closest('.opt')!.classList.toggle('is-ans', ans.includes(x.value));
      x.closest('.opt')!.classList.toggle('is-miss', x.checked && !ans.includes(x.value));
    });
    if (fs.dataset.type === 'order') syncOrder(fs);
    const exp = fs.querySelectorAll('.qz-exp > p');
    fb.replaceChildren();
    const head = document.createElement('p');
    head.className = 'qz-head';
    const msg = document.createElement('span');
    if (right) msg.textContent = L.lCorrect!; else msg.innerHTML = exp[0].querySelector('b')!.innerHTML;
    head.append(icon(right ? 'ok' : 'bad'), msg);
    fb.append(head, exp[1].cloneNode(true), exp[2].cloneNode(true));
    fb.classList.toggle('ok', right);
    fs.querySelector<HTMLButtonElement>('.qz-check')!.hidden = true;
    if (results.size === qs.length) summary();
  }
  function summary() {
    const n = [...results.values()].filter(Boolean).length, total = qs.length;
    sum.querySelector('.qz-score')!.textContent = L.lResult!.replace('{n}', String(n)).replace('{total}', String(total));
    const wrong = new Map<string, HTMLFieldSetElement>();
    qs.forEach((fs) => { if (!results.get(fs.id) && !wrong.has(fs.dataset.lesson!)) wrong.set(fs.dataset.lesson!, fs); });
    const rev = sum.querySelector('.qz-rev')!;
    rev.replaceChildren();
    if (wrong.size) {
      const p = document.createElement('p'); p.textContent = L.lReview!;
      const ul = document.createElement('ul');
      wrong.forEach((fs) => {
        const li = document.createElement('li'), href = fs.dataset.lessonHref;
        const a = document.createElement(href ? 'a' : 'span');
        if (href) (a as HTMLAnchorElement).href = href;
        a.textContent = fs.dataset.lessonTitle!;
        li.append(a); ul.append(li);
      });
      rev.append(p, ul);
    }
    const pass = sum.querySelector<HTMLElement>('.qz-pass')!;
    pass.hidden = !(n * 100 >= +L.pass! * total);
    if (!pass.hidden) { pass.querySelector('span')!.textContent = L.lPassed!; if (storageOk()) markPassed(+L.station!); }
    sum.hidden = false;
    sum.focus();
  }
  function reset() {
    results.clear();
    qs.forEach((fs) => {
      fs.classList.remove('checked', 'right', 'wrong');
      fs.querySelectorAll<HTMLInputElement>('input').forEach((x) => { x.disabled = false; x.checked = false; x.closest('.opt')!.classList.remove('is-ans', 'is-miss'); });
      fs.querySelector('.qz-fb')!.replaceChildren();
      fs.querySelector<HTMLButtonElement>('.qz-check')!.hidden = false;
      if (fs.dataset.type === 'order') shuffle(fs);
    });
    sum.hidden = true;
    qs[0]?.querySelector<HTMLElement>('input, button')?.focus();
  }

  root.classList.add('js');
  qs.forEach((fs) => {
    fs.querySelector('.qz-ans')!.setAttribute('hidden', '');
    fs.querySelector<HTMLButtonElement>('.qz-check')!.hidden = false;
    fs.querySelector('.qz-check')!.addEventListener('click', () => check(fs));
    if (fs.dataset.type === 'order') {
      fs.querySelectorAll<HTMLElement>('.mv, .qhint').forEach((x) => (x.hidden = false));
      fs.addEventListener('click', (e) => {
        const b = (e.target as HTMLElement).closest<HTMLButtonElement>('[data-mv]');
        if (!b) return;
        const li = b.closest('li')!, d = +b.dataset.mv!;
        const sib = d < 0 ? li.previousElementSibling : li.nextElementSibling;
        if (!sib) return;
        d < 0 ? sib.before(li) : sib.after(li);
        syncOrder(fs);
        (li.querySelector<HTMLButtonElement>(`[data-mv="${d}"]:not(:disabled)`) ?? li.querySelector<HTMLButtonElement>('[data-mv]:not(:disabled)'))?.focus();
      });
      shuffle(fs);
    }
  });
  root.querySelector('.qz-retry')!.addEventListener('click', reset);
}
