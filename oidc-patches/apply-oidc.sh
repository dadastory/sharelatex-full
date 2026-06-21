#!/bin/bash
# Applies the OIDC patches to Overleaf CE 6.1.2 and installs the OIDC passport
# strategy. Run inside the image build (see Dockerfile). Fails loudly on any
# patch mismatch so a base-image change can never silently produce a broken image.
set -euxo pipefail

OVERLEAF_ROOT=/overleaf
PATCH_DIR=/tmp/oidc-patches
OIDC_PKG="@govtechsg/passport-openidconnect@1.0.3"

# Optional China npm mirror acceleration. Off by default (keeps overseas builds
# on the official registry). Enable with: --build-arg CN_MIRROR=true
CN_MIRROR="${CN_MIRROR:-false}"
NPM_REGISTRY_ARGS=()
case "${CN_MIRROR,,}" in
  1 | true | yes | on)
    echo "China mirror enabled -> https://registry.npmmirror.com"
    NPM_REGISTRY_ARGS=(--registry=https://registry.npmmirror.com)
    ;;
esac

# 1) Apply source patches (paths inside each patch are services/web/...).
cd "$OVERLEAF_ROOT"
for p in "$PATCH_DIR"/*.patch; do
  echo "Applying $(basename "$p")"
  patch -p1 --forward --fuzz=0 < "$p"
done

# 2) Install the OIDC strategy. Its deps (oauth, passport-strategy, passport)
#    already exist in the hoisted root, so we install to a temp prefix and copy
#    only the new package in, leaving the workspace node_modules untouched.
mkdir -p /tmp/oidc-install
cd /tmp/oidc-install
npm install --no-save --no-audit --no-fund "${NPM_REGISTRY_ARGS[@]}" "$OIDC_PKG"
cp -rn /tmp/oidc-install/node_modules/@govtechsg "$OVERLEAF_ROOT/node_modules/"
rm -rf /tmp/oidc-install

# 3) Verify the strategy resolves as the app will import it.
cd "$OVERLEAF_ROOT/services/web"
node --input-type=module -e \
  "import { Strategy } from '@govtechsg/passport-openidconnect'; if (typeof Strategy !== 'function') { throw new Error('OIDC strategy did not load'); } console.log('OIDC strategy OK')"

echo "OIDC integration applied successfully"
