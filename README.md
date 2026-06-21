# sharelatex-full (Overleaf)

[![GitHub license](https://img.shields.io/github/license/Tuetenk0pp/sharelatex-full)](https://github.com/Tuetenk0pp/sharelatex-full/blob/master/LICENSE)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/Tuetenk0pp/sharelatex-full/build-test.yml)](https://github.com/Tuetenk0pp/sharelatex-full/actions/workflows/build-test.yml)
[![GitHub issues](https://img.shields.io/github/issues/tuetenk0pp/sharelatex-full)](https://github.com/Tuetenk0pp/sharelatex-full/issues)
[![Docker Pulls](https://img.shields.io/docker/pulls/tuetenk0pp/sharelatex-full)](https://hub.docker.com/r/tuetenk0pp/sharelatex-full)

Extended Overleaf Docker Image.
Current Features include:

- fully updated TeX Live installation, including all available packages
- support for minted
- support for `svg`-images through the addition of inkscape
- support for lilipond
- shell-escape enabled by default
- support chinese fonts
- OIDC / SSO login (ported from [ErikMichelson/overleaf-oidc](https://github.com/ErikMichelson/overleaf-oidc))
- optional China mirrors for apt and npm (`--build-arg CN_MIRROR=true`)

Have a look at the [Dockerfile](./Dockerfile) to find out more.

## Installation

### Overleaf Toolkit

Use the [Overleaf Toolkit](https://github.com/overleaf/toolkit) as described in the [Quick-Start Guide](https://github.com/overleaf/toolkit/blob/master/doc/quick-start-guide.md).
Make sure to set the `OVERLEAF_IMAGE_NAME=tuetenk0pp/sharelatex-full` variable in `config/overleaf.rc`.

Alternatively, you can use a `compose.override.yaml` file as described [here](https://github.com/overleaf/toolkit/blob/master/doc/configuration.md#the-docker-composeoverrideyml-file).
Example:

``` yml
services:
    sharelatex:
        image: dadastory/sharelatex-full
```

### Docker Compose

> [!WARNING]
> This method is not recommended. Use the Overleaf Toolkit instead.

Use the [docker-compose.yml](https://github.com/overleaf/overleaf/blob/main/docker-compose.yml) provided in the [official GitHub](https://github.com/overleaf/overleaf), but change the image to ``tuetenk0pp/sharelatex-full``.
Also, note the additional instructions in the [official Wiki](https://github.com/overleaf/overleaf/wiki/Release-Notes--4.x.x#manually-setting-up-mongodb-as-a-replica-set).

## OIDC / SSO login

This image adds OIDC login on top of Overleaf CE 6.1.2 (ported from
[ErikMichelson/overleaf-oidc](https://github.com/ErikMichelson/overleaf-oidc),
which is based on CE 5.5.x). The OIDC logic is re-applied as source patches
against the real 6.1.2 files during the build — see [`oidc-patches/`](./oidc-patches)
for the patches and the apply script. The build **fails loudly** if any patch
no longer matches the base image.

OIDC is **disabled** unless `OVERLEAF_OIDC_ISSUER` is set, so the image behaves
exactly like stock 6.1.2 by default. Set the variables below on the `sharelatex`
container (e.g. in the Toolkit's `config/variables.env` or the compose service's
`environment`).

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
| `OVERLEAF_LOGIN_OIDC_BUTTON` | no | `Log in with SSO` | login button label |

### Casdoor example

In Casdoor, create an **Application**, add the redirect URL
`https://<your-overleaf>/login/oidc/callback`, and copy the Client ID / Secret.
Casdoor's standard OIDC endpoints (replace `<casdoor>` with your host):

``` env
OVERLEAF_OIDC_ISSUER=https://<casdoor>
OVERLEAF_OIDC_AUTHORIZATION_URL=https://<casdoor>/login/oauth/authorize
OVERLEAF_OIDC_TOKEN_URL=https://<casdoor>/api/login/oauth/access_token
OVERLEAF_OIDC_USERINFO_URL=https://<casdoor>/api/userinfo
OVERLEAF_OIDC_CALLBACK_URL=https://<your-overleaf>/login/oidc/callback
OVERLEAF_OIDC_CLIENT_ID=<from Casdoor app>
OVERLEAF_OIDC_CLIENT_SECRET=<from Casdoor app>
OVERLEAF_OIDC_SCOPE=openid profile email
```

Verify the exact URLs against `https://<casdoor>/.well-known/openid-configuration`.

> [!NOTE]
> The first SSO login creates a local user from the profile's email and name,
> matched/created by `oidcIdentifier`. Keep at least one local admin account
> (do not disable local login) until SSO is verified.

## Building

Build the image yourself with:

``` sh
docker build -t sharelatex-full:6.1.2-oidc .
```

In China, accelerate apt (Tsinghua mirror) and the OIDC npm install
(npmmirror.com) with `CN_MIRROR`:

``` sh
docker build --build-arg CN_MIRROR=true -t sharelatex-full:6.1.2-oidc .
```

`CN_MIRROR` is off by default. Accepted truthy values: `true` / `1` / `yes` / `on`.
See [`oidc-patches/README.md`](./oidc-patches/README.md) for details.
