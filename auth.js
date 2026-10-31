/* Pay Royal shared authentication and role gate. Database RLS remains the security boundary. */
(() => {
  'use strict';
  const LOGIN='login.html', URL='https://jwghmsflabvzzhucuwsn.supabase.co';
  const KEY='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhbGciOiJIUzI1NiIsInJlZiI6Imp3Z2htc2ZsYWJ2enpodWN1d3NuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxNTM4NzUsImV4cCI6MjEwODcyOTg3NX0.JgUcVdMOTnYP1Txp_U2xO8R3Txvp0QEQnAvwnpxX5sU';
  const page=location.pathname.split('/').pop()||'index.html';
  if(page===LOGIN||page==='worker-login.html')return;
  document.documentElement.style.visibility='hidden';
  const allowed={
    admin:['*'],
    office_staff:['index.html','meals.html','reports.html','boarding.html','salary-check.html'],
    supervisor:['index.html','meals.html'],
    worker:['worker-portal.html']
  };
  const deny=async c=>{try{await c.auth.signOut()}catch(_){}location.replace(LOGIN+'?reason=access')};
  const start=async()=>{
    if(!window.supabase)throw new Error('Secure login service could not load.');
    const client=window.supabase.createClient(URL,KEY);
    const {data:{session},error:se}=await client.auth.getSession();
    if(se||!session){location.replace(page==='worker-portal.html'?'worker-login.html':LOGIN);return}
    const {data:p,error}=await client.from('user_profiles').select('role,is_active,factory_id,employee_id,display_name').eq('user_id',session.user.id).maybeSingle();
    if(error||!p||p.is_active!==true||!allowed[p.role]){await deny(client);return}
    if(!allowed[p.role].includes('*')&&!allowed[p.role].includes(page)){
      location.replace(p.role==='worker'?'worker-portal.html':(page==='worker-portal.html'?'index.html':'index.html'));return;
    }
    window.PayRoyalAuth={client,session,profile:p,signOut:async()=>{await client.auth.signOut();location.replace(p.role==='worker'?'worker-login.html':LOGIN)}};
    const addControl=()=>{
      const host=document.querySelector('.brand')||document.querySelector('header');
      if(!host||document.getElementById('payRoyalAccount'))return;
      const w=document.createElement('div');w.id='payRoyalAccount';w.style.cssText='display:flex;align-items:center;gap:8px;margin-left:auto;flex-wrap:wrap';
      const label=document.createElement('span');label.textContent=p.display_name||p.role.replace('_',' ');label.style.cssText='font-size:11px;color:#d7ad63;font-weight:700';
      const b=document.createElement('button');b.type='button';b.textContent='Sign out';b.style.cssText='border:1px solid #d7ad63;border-radius:30px;padding:7px 12px;background:#ffffff12;color:white;font-weight:700;min-height:36px';b.onclick=()=>window.PayRoyalAuth.signOut();
      w.append(label,b);host.appendChild(w);
    };
    if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',addControl,{once:true});else addControl();
    document.documentElement.style.visibility='';
    document.dispatchEvent(new CustomEvent('payroyal:authenticated',{detail:p}));
  };
  const run=()=>start().catch(e=>{console.error(e);document.documentElement.style.visibility='';document.body.innerHTML='<main style="font:16px system-ui;max-width:520px;margin:15vh auto;padding:24px"><h2>Pay Royal security check failed</h2><p>Refresh or contact the administrator.</p><a href="login.html">Open secure login</a></main>'});
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',run,{once:true});else run();
})();