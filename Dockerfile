FROM sharelatex/sharelatex:6.1.1

SHELL ["/bin/bash", "-cx"]

# install chinese package
RUN apt-get update && apt-get upgrade -y  \
    && apt-get install -y \
    inkscape \
    lilypond \
    latex-cjk-all \
    texlive-lang-chinese \
    texlive-lang-english \
    git \
    && rm -rf /var/lib/apt/lists/*

# download chinese fonts
RUN git clone https://github.com/Haixing-Hu/latex-chinese-fonts \
    /usr/share/fonts/opentype/latex-chinese-fonts -b master \

# update cache
RUN fc-cache -fv

# update tlmgr itself
RUN wget "https://mirror.ctan.org/systems/texlive/tlnet/update-tlmgr-latest.sh" \
    && sh update-tlmgr-latest.sh \
    && tlmgr --version

# change repository
RUN tlmgr option repository https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet/

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
