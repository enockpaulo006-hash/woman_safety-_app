# Project 17 Completion Checklist

This checklist maps the implementation to the deliverables in the assignment image.

## Deliverable Status

| Deliverable | Status | Evidence |
| --- | --- | --- |
| Anonymous incident reporting mobile application | Mostly complete | Flutter app has reporting form, GPS capture, consent, offline queue, and backend submission. |
| GIS incident hotspot mapping platform | Mostly complete | Admin portal includes a Leaflet map filtered by category, location type, time bucket, and date range. |
| Automated monthly policy brief generator | Improved | Portal generates a monthly brief, supports print, and now includes CSV export. |
| Moderation and data quality admin portal | Mostly complete | Portal supports staff login, dashboard, moderation filters, status changes, and report history. |
| Privacy, ethics, and data security report | Complete draft | See `docs/PRIVACY_ETHICS_SECURITY_REPORT.md`. |

## Remaining Before Final Demo

1. Prepare the database.
   - Create a PostgreSQL database named `women_safety`.
   - Enable PostGIS and pgcrypto.
   - Import `project17-schema.sql`.
   - Run Django migrations for built-in apps and `accounts`.

2. Create staff access.
   - Create a Django superuser or staff user.
   - Confirm the user can open `/portal/`.

3. Seed demo reports.
   - Submit several mobile reports.
   - Approve some reports in moderation.
   - Confirm approved reports appear on the hotspot map and monthly brief.

4. Configure mobile backend URL.
   - Update the app setting or build with `API_BASE_URL`.
   - Use the computer LAN IP when testing on a real phone.

5. Configure Google sign-in only if required.
   - Add backend `GOOGLE_OAUTH_CLIENT_IDS`.
   - Configure Android OAuth in the Google Cloud Console.
   - Confirm mobile sign-in returns a backend session token.

6. Run final checks.
   - `python manage.py check`
   - `python manage.py showmigrations`
   - `flutter analyze`
   - Submit one report from mobile and verify the full workflow.

## Backend Commands

From `backend`:

```powershell
.\venv\Scripts\python.exe manage.py check
.\venv\Scripts\python.exe manage.py migrate
.\venv\Scripts\python.exe manage.py createsuperuser
.\venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
```

If the report tables do not exist yet, import the SQL file first:

```powershell
psql -U postgres -d women_safety -f ..\project17-schema.sql
```

## Mobile Commands

From `women_safety_app`:

```powershell
..\flutter\bin\flutter.bat pub get
..\flutter\bin\flutter.bat analyze
..\flutter\bin\flutter.bat run --dart-define=API_BASE_URL=http://YOUR-LAN-IP:8000/api/v1
```

## Demo Script

1. Start the backend server.
2. Open the mobile app.
3. Register or sign in.
4. Submit a report with category, location type, incident time, GPS, and consent.
5. Open the admin portal at `/portal/`.
6. Review the submitted report in moderation.
7. Approve the report.
8. Open the hotspot map and confirm the marker appears.
9. Open monthly briefs, select the report month, then print or download CSV.

## Known Implementation Notes

- The backend uses PostGIS through `django.contrib.gis`.
- The `reports` tables are mapped with `managed = False`, so Django will not create them automatically.
- The SQLite file is not the active project database.
- The admin map uses online Leaflet/OpenStreetMap assets, so internet access helps during demo.
- Exact GPS points should stay inside the admin portal; public briefs should use aggregate patterns.
## Demo Credentials

A local demo staff account has been prepared for portal testing:

- Username: `demo.admin`
- Password: `Admin@12345`
- Portal URL: `http://127.0.0.1:8000/portal/`

The database also contains demo incident reports with `P17-DEMO-*` references so the dashboard, hotspot map, and monthly brief are populated.

To reseed the same demo data from `backend`:

```powershell
.\venv\Scripts\python.exe manage.py shell -c "exec(open('seed_project17_demo_data.py', encoding='utf-8').read())"
```
