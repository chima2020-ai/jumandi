# Jumandi Admin (React)

Web admin at **https://jumandi.onrender.com/admin** (served by the FastAPI backend).

## Run locally

```bash
cd admin_web
npm install
npm run dev
```

Open **http://localhost:5173** (API defaults to production URL in dev).

## Production build

Built automatically in Docker on Render deploy. Manual build:

```bash
cd admin_web
npm install
npm run build
```

Output goes to `admin_web/dist` and is served at `/admin`.
