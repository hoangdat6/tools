# App deployment workspace

- `Makefile`: stable deployment commands, runnable from any directory.
- `env/deploy.env`: paths and Compose service names consumed by Make.
- `env/.env.be` and `env/.env.fe`: application environment values.
- `compose.yml`: app-level Compose stack; create it from `compose.yml.example`.
- `nginx-proxy-manager/`: owned by the `nginx-proxy-manager` setup module.
- `~/sources/backend` and `~/sources/frontend`: application source checkouts.

Before the first deployment, update `env/deploy.env`, fill the application env
files, create `compose.yml`, and place the frontend image archive at the path
configured by `FRONTEND_IMAGE_ARCHIVE`.
