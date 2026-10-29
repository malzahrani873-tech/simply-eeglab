// Search with the Pagefind index of this page's language. Loaded on /search/ only.
const input = document.querySelector<HTMLInputElement>('#q')!;
const status = document.querySelector<HTMLElement>('#s-status')!;
const list = document.querySelector<HTMLOListElement>('#s-res')!;
const L = status.dataset;
let pf: any = null;
let seq = 0;

async function load() {
  if (!pf) {
    pf = await import(/* @vite-ignore */ list.dataset.pf!);
    await pf.init?.();
  }
  return pf;
}

async function run(q: string) {
  const my = ++seq;
  const u = new URL(location.href);
  q ? u.searchParams.set('q', q) : u.searchParams.delete('q');
  history.replaceState(null, '', u);
  if (!q.trim()) { list.replaceChildren(); status.textContent = ''; return; }
  status.textContent = L.lLoading!;
  try {
    const search = await (await load()).debouncedSearch(q, {}, 250);
    if (my !== seq || search === null) return;
    const data = await Promise.all(search.results.slice(0, 20).map((r: any) => r.data()));
    if (my !== seq) return;
    list.replaceChildren(...data.map((d: any) => {
      const li = document.createElement('li');
      const a = document.createElement('a');
      a.href = d.url; a.textContent = d.meta?.title ?? d.url;
      const p = document.createElement('p');
      p.innerHTML = d.excerpt; // Pagefind escapes the text and adds <mark> only.
      li.append(a, p);
      return li;
    }));
    status.textContent = search.results.length ? L.lCount!.replace('{n}', String(search.results.length)) : L.lNone!;
  } catch {
    status.textContent = L.lNone!;
  }
}

input.addEventListener('input', () => run(input.value));
input.form!.addEventListener('submit', (e) => { e.preventDefault(); run(input.value); });
const q0 = new URLSearchParams(location.search).get('q');
if (q0) { input.value = q0; run(q0); }
