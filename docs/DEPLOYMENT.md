# Deployment (GitHub Pages)

## What this app uses

- **Stack**: Vite, React, Zustand (with `persist` → localStorage).
- **Data**: All state lives in the browser’s localStorage. No server or database; nothing is sent to GitHub or any backend.

## Initial setup (one-time)

1. **Create the `gh-pages` branch**: From your repo root, run `git checkout -b gh-pages` then `git push -u origin gh-pages` (or create an empty branch on GitHub). The first workflow run will build and overwrite this branch with the contents of `dist/`.
2. **Enable GitHub Pages**: In the repo, go to **Settings → Pages**. Under **Source**, choose **Deploy from a branch**. Set **Branch** to `gh-pages` and **Folder** to `/ (root)`. Save. The site will be at `https://<user>.github.io/MTG-Tournament-Tracker/` once the workflow has run.

## Environments

| Branch   | Role        | Served at                                      |
|----------|-------------|-------------------------------------------------|
| `main`   | Development | Local only (`npm run dev`)                      |
| `gh-pages` | Production  | `https://<user>.github.io/MTG-Tournament-Tracker/` |

## How deployment works

1. You push (or merge) to the `gh-pages` branch.
2. GitHub Actions runs the workflow in [.github/workflows/deploy-gh-pages.yml](../.github/workflows/deploy-gh-pages.yml): checkout → `npm ci` → `npm run build`.
3. The workflow deploys the contents of `dist/` to the `gh-pages` branch (overwriting it with the built site).
4. GitHub Pages serves the site from that branch.

## Release to prod (step-by-step)

1. Merge `main` into `gh-pages` (or push directly to `gh-pages`).
2. Push: `git push origin gh-pages`.
3. In the repo, open **Actions** and wait for the “Deploy to GitHub Pages” workflow to finish.
4. Open `https://<your-username>.github.io/MTG-Tournament-Tracker/` (replace `<your-username>` with your GitHub username).

## Making changes

- **Change base URL** (e.g. after renaming the repo): Edit `base` in [vite.config.ts](../vite.config.ts). Redeploy by pushing to `gh-pages`.
- **Change the workflow**: Edit [.github/workflows/deploy-gh-pages.yml](../.github/workflows/deploy-gh-pages.yml). Commit and push to a branch, then merge into `gh-pages` (or push to `gh-pages`).
- **Node version**: Update the `node-version` in the workflow (e.g. `'20'` → `'22'`). Optionally add an `engines` field in `package.json` for local consistency.

## Troubleshooting

| Issue | What to check |
|-------|----------------|
| Build fails | Node version in workflow; `npm ci` and lockfile; workflow logs in **Actions**. |
| 404 on routes (e.g. `/stats`) | Ensure the Vite plugin copies `index.html` to `404.html` (see [vite.config.ts](../vite.config.ts)). |
| Blank page or wrong assets | `base` in [vite.config.ts](../vite.config.ts) must match repo name: `/MTG-Tournament-Tracker/`. |
| Pages not updating | **Settings → Pages**: source = “Deploy from a branch”, branch = `gh-pages`, folder = `/ (root)`. Check workflow status and browser cache. |

## Where data lives

Production uses **browser localStorage** only (key: `budget-league-tracker-storage`). Data is not sent to GitHub or any server; each device/browser has its own copy.
