# Opusio Shop

Luxury handcrafted jewelry – full-stack shop project.

## Structure
- shop_frontend: Vue 3 + Vuetify
- shop_backend: Python backend

## Status
Early development – UI foundation and project structure in place.

## Environment & Secrets

This project uses Supabase for backend services. To keep secrets safe, follow these guidelines:

- Local environment file: `shop_frontend/.env.local`
	- Create this file from `shop_frontend/.env.example` and fill in your real keys.
	- Never commit `.env.local` to git. It is ignored by `.gitignore`.

- Keys you will need locally:
	- `VITE_SUPABASE_URL` — your Supabase project URL
	- `VITE_SUPABASE_ANON_KEY` — the publishable anon key (client-side only)

- Service role / private keys:
	- Do NOT put the `service_role` key in any client-side file. Store it only in server/Edge Function secrets or your hosting provider's secret store.

- Rotation & compromise:
	- If a key is ever committed or leaked, rotate it immediately in the Supabase Console and update your local and deployment environment variables.

- Hooks & safety:
	- A repository pre-commit hook exists at `.githooks/pre-commit` to prevent accidental commits of env files. Enable it locally:

```bash
git config core.hooksPath .githooks
```

- Quick local setup:

```bash
cd shop_frontend
cp .env.example .env.local
# edit .env.local and add real values (do not commit)
```

If you want help rotating keys, setting up CI secrets, or adding stronger secret scanning (pre-commit/detect-secrets), ask and I will prepare those steps.
