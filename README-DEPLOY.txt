PAY ROYAL — DEPLOYMENT NOTES

Files:
index.html = main manpower app
website-index.html = company website
salary-check.html = salary-check portal
meals.html, boarding.html, reports.html, settings.html = app pages
manifest.webmanifest and sw.js = PWA metadata/offline shell

IMPORTANT SECURITY:
The Supabase anon key is intentionally a placeholder. Paste the project's anon public key into SUPABASE_ANON_KEY in every HTML file (or centralize shared JS before launch). Do not use service_role key. RLS disabled is unsafe for salary/payroll data. Salary portal code lookup is not authentication and cannot securely restrict access to the employee's own row. Enable Auth + RLS policies before public launch.

SCHEMA ASSUMPTIONS:
This front end expects employees with labour_code/name/gender/factory/daily_rate/ot_rate; attendance with labour_code/work_date/status/ot_hours/late_minutes/shift_day/late_mark and a UNIQUE(labour_code,work_date); meals with labour_code/meal_date/breakfast/lunch/dinner and UNIQUE(labour_code,meal_date); settlements with labour_code and salary fields. Confirm your actual schema first.

GITHUB / NETLIFY:
1. Open https://github.com/agrogeninfo-cell/royal-hires-website
2. Click Add file > Upload files. Upload the contents of this folder (not the ZIP itself) to the repository root on main, then Commit changes.
3. If GitHub upload is easier, unzip the supplied ZIP first on a computer. On Android, GitHub's browser upload may be limited for folders; uploading each file is possible but tedious.
4. Open https://app.netlify.com/ and sign in. Add new project > Import an existing project > GitHub. Authorize Netlify and choose agrogeninfo-cell/royal-hires-website.
5. Build command: leave blank. Publish directory: . (a single dot). Deploy.
6. In Site configuration > General > Site details, set/change site name to payroyal if available. If taken, Netlify will request another name.
7. Later commits to main automatically redeploy.
8. Main app: https://payroyal.netlify.app/ (if site name is available). Website page: /website-index.html. Salary portal: /salary-check.html.

TESTING:
- Add the anon key before testing.
- Employee reads may fall back to demo rows if table query fails; confirm the toast/console and Supabase data before relying on it.
- Attendance date change should show only selected-date records. Upsert requires UNIQUE(labour_code,work_date).
- Realtime requires Supabase Realtime enabled for employees and attendance tables.
- Salary privacy is NOT safe with RLS disabled; do not use public payroll data until secured.
