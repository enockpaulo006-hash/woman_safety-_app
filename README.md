# Project 17 - Women Safety Incident Reporting Platform

This repository contains a Flutter mobile app and Django/PostGIS backend for anonymous safety incident reporting, moderation, hotspot mapping, and monthly policy briefs.

## Main Folders

- `women_safety_app/` - Flutter mobile app.
- `backend/` - Django REST API and staff admin portal.
- `project17-schema.sql` - PostGIS database schema and seed taxonomies.
- `docs/` - completion checklist and privacy/security report.

## Deliverables

1. Anonymous mobile incident reporting app.
2. GIS hotspot mapping platform.
3. Monthly policy brief generator with print and CSV export.
4. Moderation and data quality admin portal.
5. Privacy, ethics, and data security report.

## Quick Start

See `docs/PROJECT_COMPLETION_CHECKLIST.md` for the final setup and demo sequence.

Backend:

```powershell
cd backend
.\venv\Scripts\python.exe manage.py check
.\venv\Scripts\python.exe manage.py migrate
.\venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
```

Mobile:

```powershell
cd women_safety_app
..\flutter\bin\flutter.bat pub get
..\flutter\bin\flutter.bat run --dart-define=API_BASE_URL=http://YOUR-LAN-IP:8000/api/v1
```
portal.admin / Admin@12345        -> all pages
moderator.user / Moderator@12345  -> dashboard, moderation, privacy
gis.analyst / Gis@12345           -> dashboard, hotspot map
policy.officer / Policy@12345     -> dashboard, map, briefs, privacy
police.partner / Police@12345     -> dashboard, map, briefs
tawla.partner / Tawla@12345       -> dashboard, map, briefs, privacy
researcher.user / Researcher@12345 -> dashboard, map, briefs, privacy