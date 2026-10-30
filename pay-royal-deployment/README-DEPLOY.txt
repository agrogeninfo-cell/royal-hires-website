PAY ROYAL — DEPLOYMENT NOTES

This folder contains deployment notes for the Pay Royal package. The original website files in the repository root have not been changed.

Package files intended for deployment:
- index.html — main manpower app
- website-index.html — company website
- salary-check.html — salary-check portal
- meals.html, boarding.html, reports.html, settings.html — app pages
- manifest.webmanifest and sw.js — PWA metadata/offline shell

IMPORTANT SECURITY:
The Supabase anon key is intentionally a placeholder. Paste the project's anon public key into SUPABASE_ANON_KEY in every HTML file (or centralize shared JS before launch). Do not use service_role key. RLS disabled is unsafe for salary/payroll data. Salary portal code lookup is not authentication and cannot securely restrict access to an employee's own row. Enable Auth + RLS policies before public launch.

SCHEMA ASSUMPTIONS:
This front end expects employees with labour_code/name/gender/factory/daily_rate/ot_rate; attendance with labour_code/work_date/status/ot_hours/late_minutes/shift_day/late_mark and a UNIQUE(labour_code,work_date); meals with labour_code/meal_date/breakfast/lunch/dinner and UNIQUE(labour_code,meal_date); settlements with labour_code and salary fields. Confirm your actual schema first.

The ZIP itself cannot be uploaded as a binary archive through the connected GitHub file-writing action. This note is being added without overwriting existing files. The actual HTML files still need to be added separately before deployment.