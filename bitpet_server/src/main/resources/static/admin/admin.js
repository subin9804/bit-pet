/*
  관리 페이지 공통 (신고·문의·푸시) — 로그인, API 호출, 헤더 메뉴.
  banners.html 과 같은 방식: 토큰은 sessionStorage 에만(탭을 닫으면 로그아웃), 갱신 없이 만료되면 다시 로그인.
  어드민 판정은 서버가 한다 — 각 페이지의 첫 /api/v1/admin/** 호출이 403 이면 로그인 화면으로 돌아간다.

  페이지는 <header data-page="reports"> 같은 빈 자리와 #login, #app 을 두고
  Admin.boot(async () => { 첫 로딩 }) 을 부른다.
*/
(() => {
  const $ = (id) => document.getElementById(id);
  const TOKEN_KEY = 'tailog.admin.token';
  const PAGES = [
    ['banners', '배너'],
    ['reports', '신고·정지'],
    ['inquiries', '문의함'],
    ['push', '전체 푸시'],
  ];
  let token = null;
  try { token = sessionStorage.getItem(TOKEN_KEY); } catch (_) {}
  let onReady = null;

  function setToken(t) {
    token = t;
    try { t ? sessionStorage.setItem(TOKEN_KEY, t) : sessionStorage.removeItem(TOKEN_KEY); } catch (_) {}
  }

  // 401·403 은 로그인 화면으로 돌리고 'AUTH' 로 던진다 — 호출부는 그 경우 따로 알리지 않는다
  async function api(path, opts = {}) {
    const headers = { ...(opts.headers || {}) };
    if (token) headers.Authorization = 'Bearer ' + token;
    let body = opts.body;
    if (opts.json !== undefined) {
      headers['Content-Type'] = 'application/json';
      body = JSON.stringify(opts.json);
    }
    const res = await fetch(path, { method: opts.method || 'GET', headers, body });
    let payload = null;
    try { payload = await res.json(); } catch (_) {}
    if (res.status === 401) { showLogin('로그인이 만료됐어요. 다시 로그인해 주세요.'); throw new Error('AUTH'); }
    if (res.status === 403 && path.startsWith('/api/v1/admin/')) {
      showLogin((payload && payload.error && payload.error.message) || '관리자 계정이 아니에요.');
      throw new Error('AUTH');
    }
    if (!res.ok || !payload || payload.success === false) {
      throw new Error((payload && payload.error && payload.error.message) || ('요청 실패 (' + res.status + ')'));
    }
    return payload.data;
  }

  /** 실패를 화면에 알린다. 로그인 화면으로 돌아간 경우는 조용히 */
  function report(err, el) {
    if (err.message === 'AUTH') return;
    if (el) el.textContent = err.message; else alert(err.message);
  }

  function showLogin(msg) {
    setToken(null);
    $('app').classList.add('hidden');
    $('login').classList.remove('hidden');
    $('loginErr').textContent = msg || '';
  }

  async function start() {
    await onReady();                     // 어드민이 아니면 여기서 403 → 로그인 화면
    $('login').classList.add('hidden');
    $('app').classList.remove('hidden');
    try {
      const me = await api('/api/v1/auth/me');
      $('who').textContent = (me && (me.nickname || me.email)) || '';
    } catch (_) {}
  }

  function renderHeader() {
    const h = document.querySelector('header[data-page]');
    const cur = h.dataset.page;
    h.innerHTML = `<h1>tailog 관리</h1>
      <nav>${PAGES.map(([p, n]) => `<a href="/admin/${p}" class="${p === cur ? 'on' : ''}">${n}</a>`).join('')}</nav>
      <span class="who" id="who"></span><button id="logout" class="small">로그아웃</button>`;
    $('logout').addEventListener('click', () => showLogin(''));
  }

  function wireLogin() {
    $('loginForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      $('loginErr').textContent = '';
      const btn = e.submitter; btn.disabled = true;
      try {
        const res = await fetch('/api/v1/auth/login', {
          method: 'POST', headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email: $('email').value.trim(), password: $('pw').value }),
        });
        const p = await res.json().catch(() => null);
        if (!res.ok || !p || !p.success) throw new Error((p && p.error && p.error.message) || '로그인에 실패했어요');
        setToken(p.data.accessToken);
        $('pw').value = '';
        await start();
      } catch (err) {
        report(err, $('loginErr'));
      } finally { btn.disabled = false; }
    });
  }

  const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c]));
  const fmt = (iso) => iso ? new Date(iso).toLocaleString('ko-KR', { dateStyle: 'short', timeStyle: 'short' }) : '';

  /** Spring Page 응답 아래에 '이전 · n / N · 다음' 을 그린다 */
  function pager(el, page, go) {
    if (!page || page.totalPages <= 1) { el.innerHTML = ''; return; }
    el.innerHTML = `<button class="small" ${page.first ? 'disabled' : ''} data-p="${page.number - 1}">이전</button>
      <span>${page.number + 1} / ${page.totalPages}</span>
      <button class="small" ${page.last ? 'disabled' : ''} data-p="${page.number + 1}">다음</button>`;
    el.querySelectorAll('button').forEach((b) => b.addEventListener('click', () => go(parseInt(b.dataset.p, 10))));
  }

  window.Admin = {
    api, report, esc, fmt, pager,
    boot(ready) {
      onReady = ready;
      renderHeader();
      wireLogin();
      if (token) start().catch(() => {}); else showLogin('');
    },
  };
})();
