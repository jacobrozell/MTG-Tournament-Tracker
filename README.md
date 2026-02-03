# Budget League Tracker

MTG league tournament tracker: tournaments, attendance, pods, achievements, and stats. Data is stored in the browser (localStorage); no backend.

**Deploying to GitHub Pages:** see [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).

### Blank white page after deploy

1. **Open DevTools** (F12) → **Console**. Look for 404s on JS/CSS (wrong `base` or repo name) or red errors (runtime crash).
2. **URL**: Use `https://<user>.github.io/MTG-Tournament-Tracker/` (trailing slash and repo name). Wrong path = 404 or blank.
3. **Router basename**: The app uses `import.meta.env.BASE_URL` so React Router matches under the repo subpath. If you renamed the repo, update `base` in `vite.config.ts` to match and redeploy.
