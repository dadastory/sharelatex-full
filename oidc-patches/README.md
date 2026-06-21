# OIDC login for Overleaf CE 6.1.2

Ports the OIDC login from [ErikMichelson/overleaf-oidc](https://github.com/ErikMichelson/overleaf-oidc)
(which is based on Overleaf CE **5.5.x**) onto this image's **6.1.2** base.

The fork can't be used directly: 6.1.2 migrated many files from `.js` to `.mjs`
and refactored auth helpers, so copying the fork's files would break the build.
Instead, only the OIDC logic is re-applied as source patches against the real
6.1.2 files. `apply-oidc.sh` runs during `docker build` and **fails the build**
if any patch no longer matches (e.g. after a base-image bump).

## What it changes

- `models/User.mjs` — adds `oidcIdentifier` field
- `Features/Authentication/AuthenticationController.mjs` — OIDC login/callback/verify methods
- `infrastructure/Server.mjs` — registers the `oidc` passport strategy (only when `OVERLEAF_OIDC_ISSUER` is set)
- `router.mjs` — adds `/login/oidc` and `/login/oidc/callback`
- `infrastructure/ExpressLocals.mjs` — exposes the SSO button flags
- `views/user/login.pug` — adds the "Log in with SSO" button
- installs npm package `@govtechsg/passport-openidconnect`

## Build

```bash
docker build -t sharelatex-full:6.1.2-oidc .
```

In China, accelerate the build via domestic mirrors:

```bash
docker build --build-arg CN_MIRROR=true -t sharelatex-full:6.1.2-oidc .
```

`CN_MIRROR` is off by default (overseas builds use the official sources).
Accepted truthy values: `true` / `1` / `yes` / `on`. When enabled it switches:

- **apt** -> `mirrors.tuna.tsinghua.edu.cn` (Ubuntu noble; rewrites `ubuntu.sources`)
- **npm** (the OIDC package) -> `registry.npmmirror.com`

TeXLive and the GitHub font clone already use domestic mirrors in the Dockerfile
regardless of this switch.

## Environment variables (set on the sharelatex container)

| Variable | Required | Default | Notes |
|---|---|---|---|
| `OVERLEAF_OIDC_ISSUER` | yes | — | Setting this **enables** OIDC |
| `OVERLEAF_OIDC_AUTHORIZATION_URL` | yes | — | |
| `OVERLEAF_OIDC_TOKEN_URL` | yes | — | |
| `OVERLEAF_OIDC_USERINFO_URL` | yes | — | |
| `OVERLEAF_OIDC_CLIENT_ID` | yes | — | |
| `OVERLEAF_OIDC_CLIENT_SECRET` | yes | — | |
| `OVERLEAF_OIDC_CALLBACK_URL` | yes | — | `https://<your-overleaf>/login/oidc/callback` |
| `OVERLEAF_OIDC_SCOPE` | no | `openid profile email` | |
| `OVERLEAF_OIDC_MATCHING` | no | `id` | `id` or `username` — which profile field maps to the local account |
| `OVERLEAF_LOGIN_OIDC_BUTTON` | no | `Log in with SSO` | button label |

## Casdoor settings

In Casdoor, create an **Application** and copy its Client ID / Client Secret.
Add the redirect URL `https://<your-overleaf>/login/oidc/callback`.

Casdoor's standard OIDC endpoints (replace `<casdoor>` with your host):

```
OVERLEAF_OIDC_ISSUER=https://<casdoor>
OVERLEAF_OIDC_AUTHORIZATION_URL=https://<casdoor>/login/oauth/authorize
OVERLEAF_OIDC_TOKEN_URL=https://<casdoor>/api/login/oauth/access_token
OVERLEAF_OIDC_USERINFO_URL=https://<casdoor>/api/userinfo
OVERLEAF_OIDC_CALLBACK_URL=https://<your-overleaf>/login/oidc/callback
OVERLEAF_OIDC_CLIENT_ID=<from Casdoor app>
OVERLEAF_OIDC_CLIENT_SECRET=<from Casdoor app>
OVERLEAF_OIDC_SCOPE=openid profile email
```

You can confirm the exact URLs against Casdoor's discovery document at
`https://<casdoor>/.well-known/openid-configuration`.

> Note: OIDC accounts are matched/created by `oidcIdentifier`. The first SSO
> login creates a local user from the profile's email and name. Keep at least
> one local admin account (don't disable local login) until SSO is verified.
