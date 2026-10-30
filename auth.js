/* Pay Royal shared authentication and role gate. Database RLS remains the security boundary. */
(() => {
  'use strict';
  const LOGIN = 'login.html';
  const URL = 'https://jwghmsflabvzzhucuwsn.supabase.co';
  const KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3Z2htc2ZsYWJ2enpodWN1d3NuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxNTM4NzUsImV4cCI6MjEwODcyOTg3NX0.JgUcVdMOTnYP1Txp_U2xO8R3Txvp0QEQnAvwnpxX5sU';
  const page = location.pathname.split('/').pop() || 'index.html';
  if (page === LOGIN) return;
  document.documentElement.style.visibility = 'hidden';
  const allowed = {
    admin: ['*'],
    office_staff: ['index.html','meals.html','reports.html','boarding.html','salary-check.html'],
    supervisor: ['index.html','meals.html'],
    worker: ['salary-check.html']
  };
  const deny = async (client, message) => {
    try { await client.auth.signOut(); } catch (_) {}
    location.replace(LOGIN + '?reason=' + encodeURIComponent(message || 'access'));
  };
  const start = async () => {
    if (!window.supabase) throw new Error('Secure login service could not load. Check your connection and refresh.');
    const client = window.supabase.createClient(URL, KEY);
    const { data: { session }, error: sessionError } = await client.auth.getSession();
    if (sessionError || !session) { location.replace(LOGIN); return; }
    const { data: profile, error } = await client.from('user_profiles')
      .select('role,is_active,factory_id,employee_id,display_name')
      .eq('user_id', session.user.id).maybeSingle();
    if (error || !profile || profile.is_active !== true || !allowed[profile.role]) {
      await deny(client, 'access'); return;
    }
    if (!allowed[profile.role].includes('*') && !allowed[profile.role].includes(page)) {
      location.replace(profile.role === 'worker' ? 'salary-check.html' : 'index.html'); return;
    }
    window.PayRoyalAuth = {
      client, session, profile,
      signOut: async () => { await client.auth.signOut(); location.replace(LOGIN); }
    };
    const addAccountControl = () => {
      const host = document.querySelector('.brand') || document.querySelector('header');
      if (!host || document.getElementById('payRoyalAccount')) return;
      const wrap = document.createElement('div');
      wrap.id = 'payRoyalAccount';
      wrap.style.cssText = 'display:flex;align-items:center;gap:8px;margin-left:auto;flex-wrap:wrap';
      const label = document.createElement('span');
      label.textContent = profile.display_name || profile.role.replace('_',' ');
      label.style.cssText = 'font-size:11px;color:#d7ad63;font-weight:700';
      const button = document.createElement('button');
      button.type = 'button'; button.textContent = 'Sign out';
      button.style.cssText = 'border:1px solid #d7ad63;border-radius:30px;padding:7px 12px;background:#ffffff12;color:white;font-weight:700;min-height:36px';
      button.addEventListener('click', () => window.PayRoyalAuth.signOut());
      wrap.append(label,button); host.appendChild(wrap);
    };
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', addAccountControl, {once:true});
    else addAccountControl();
    document.documentElement.style.visibility = '';
    document.dispatchEvent(new CustomEvent('payroyal:authenticated',{detail:profile}));
  };
  const run = () => start().catch(error => {
    console.error('Pay Royal authentication:', error);
    document.documentElement.style.visibility = '';
    document.body.innerHTML = '<main style="font:16px system-ui;max-width:520px;margin:15vh auto;padding:24px"><h2>Pay Royal security check failed</h2><p>Authentication could not be verified. Please refresh or contact the administrator.</p><a href="login.html">Open secure login</a></main>';
  });
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', run, {once:true});
  else run();
})();