FROM sharelatex/sharelatex:6.1.2

SHELL ["/bin/bash", "-cx"]

# China mirror switch: set --build-arg CN_MIRROR=true to use domestic mirrors
# (Tsinghua) for apt and npmmirror.com for npm. Off by default.
ARG CN_MIRROR=false

# switch apt sources to Tsinghua mirror when CN_MIRROR is enabled
RUN case "${CN_MIRROR,,}" in \
      1 | true | yes | on) \
        echo "China mirror enabled -> apt via mirrors.tuna.tsinghua.edu.cn" \
        && sed -i \
          -e 's@http://archive.ubuntu.com/ubuntu/@https://mirrors.tuna.tsinghua.edu.cn/ubuntu/@g' \
          -e 's@http://security.ubuntu.com/ubuntu/@https://mirrors.tuna.tsinghua.edu.cn/ubuntu/@g' \
          /etc/apt/sources.list.d/ubuntu.sources ;; \
    esac

# install chinese package
# hold nodejs so apt-get upgrade does not pull a new node from deb.nodesource.com
# (slow/blocked in China and could break Overleaf's bundled node runtime)
RUN apt-get update && apt-mark hold nodejs && apt-get upgrade -y  \
    && apt-get install -y \
    inkscape \
    lilypond \
    latex-cjk-all \
    texlive-lang-chinese \
    texlive-lang-english \
    git \
    && rm -rf /var/lib/apt/lists/*

# download chinese fonts
#RUN git clone -b master https://gh.llkk.cc/https://github.com/Haixing-Hu/latex-chinese-fonts \
RUN mkdir -p /usr/share/fonts/opentype/latex-chinese-fonts
COPY ./chinese /usr/share/fonts/opentype/latex-chinese-fonts
RUN fc-cache -fv

# update tlmgr itself
RUN wget "https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet/update-tlmgr-latest.sh" \
    && sh update-tlmgr-latest.sh \
    && tlmgr --version

# change repository
RUN tlmgr option repository https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet

# enable tlmgr to install ctex
RUN tlmgr update texlive-scripts 

# update packages
RUN tlmgr update --self --all && \
    tlmgr install fandol && \
    tlmgr install scheme-full

# recreate symlinks
RUN tlmgr path add

# enable shell-escape by default:
RUN TEXLIVE_FOLDER=$(find /usr/local/texlive/ -type d -name '20*') \
    && echo % enable shell-escape by default >> /$TEXLIVE_FOLDER/texmf.cnf \
    && echo shell_escape = t >> /$TEXLIVE_FOLDER/texmf.cnf

# integrate OIDC login (ported from ErikMichelson/overleaf-oidc to CE 6.1.2)
# CN_MIRROR (declared above) also routes the npm package via npmmirror.com
COPY ./oidc-patches /tmp/oidc-patches
RUN CN_MIRROR=${CN_MIRROR} bash /tmp/oidc-patches/apply-oidc.sh \
    && rm -rf /tmp/oidc-patches
