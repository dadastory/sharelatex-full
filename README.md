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

### Casdoor 配置（中文）

以 Casdoor 作为 OIDC 身份提供方的完整配置步骤。

**1. 在 Casdoor 新建应用**

登录 Casdoor 管理后台 → **应用（Applications）** → **添加**，填写：

| 字段 | 填写内容 |
|---|---|
| 名称 / 显示名称 | 例如 `overleaf` |
| 重定向 URL（Redirect URLs） | `https://<你的overleaf域名>/login/oidc/callback` |
| 授权类型（Grant types） | 勾选 `Authorization Code` |
| Token 格式 | `JWT`（默认即可） |
| 关联组织（Organization） | 选择用户所在组织 |

保存后在应用详情页获取 **Client ID** 与 **Client Secret**。

> 重定向 URL 必须与 `OVERLEAF_OIDC_CALLBACK_URL` **完全一致**（协议、域名、路径），否则 Casdoor 会拒绝回调。

**2. 确认 Casdoor 的 OIDC 端点**

打开 discovery 文档，以实际返回为准（替换 `<casdoor>` 为你的域名）：

```
https://<casdoor>/.well-known/openid-configuration
```

其中 `issuer` / `authorization_endpoint` / `token_endpoint` / `userinfo_endpoint` 即下面要填的值。Casdoor 标准端点通常为：

| 端点 | 路径 |
|---|---|
| issuer | `https://<casdoor>` |
| authorization | `https://<casdoor>/login/oauth/authorize` |
| token | `https://<casdoor>/api/login/oauth/access_token` |
| userinfo | `https://<casdoor>/api/userinfo` |

**3. 在 Overleaf 设置环境变量**

加到 Overleaf Toolkit 的 `config/variables.env`，或 compose 中 `sharelatex` 服务的 `environment`：

``` env
OVERLEAF_OIDC_ISSUER=https://<casdoor>
OVERLEAF_OIDC_AUTHORIZATION_URL=https://<casdoor>/login/oauth/authorize
OVERLEAF_OIDC_TOKEN_URL=https://<casdoor>/api/login/oauth/access_token
OVERLEAF_OIDC_USERINFO_URL=https://<casdoor>/api/userinfo
OVERLEAF_OIDC_CALLBACK_URL=https://<你的overleaf域名>/login/oidc/callback
OVERLEAF_OIDC_CLIENT_ID=<Casdoor 应用的 Client ID>
OVERLEAF_OIDC_CLIENT_SECRET=<Casdoor 应用的 Client Secret>
OVERLEAF_OIDC_SCOPE=openid profile email
OVERLEAF_LOGIN_OIDC_BUTTON=使用 SSO 登录
```

设置 `OVERLEAF_OIDC_ISSUER` 后即自动启用 OIDC，登录页出现 SSO 按钮。重启 `sharelatex` 容器生效。

**4. 验证**

访问登录页 → 点 "使用 SSO 登录" → 跳转 Casdoor 登录 → 跳回 Overleaf。首次 SSO 登录会按 Casdoor 返回的 email/姓名自动创建本地用户，并以 `oidcIdentifier` 关联。

**常见问题**

| 现象 | 原因 |
|---|---|
| 回调报 `redirect_uri` 不匹配 | Casdoor 应用的 Redirect URL 与 `OVERLEAF_OIDC_CALLBACK_URL` 不一致 |
| 跳回后报错 / 拿不到用户 | scope 缺 `email`/`profile`，或 userinfo 端点路径不对 |
| 点 SSO 按钮提示 disabled | `OVERLEAF_OIDC_ISSUER` 未设置，或容器未重启 |
| HTTPS 证书错误 | Casdoor 使用自签证书，Overleaf 容器不信任；生产建议用受信任证书 |

> [!NOTE]
> The first SSO login creates a local user from the profile's email and name,
> matched/created by `oidcIdentifier`. Keep at least one local admin account
> (do not disable local login) until SSO is verified.
> 在 SSO 验证通过前，请务必保留一个本地管理员账号、不要关闭本地登录，否则配置错误会把自己锁在外面。

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
