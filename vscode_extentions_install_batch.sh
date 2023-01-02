#!/bin/bash

# NOTE: インストールされている拡張機能を表示「code --list-extensions」

# Visual Studio Code :: Package list
pkglist=(
bierner.markdown-preview-github-styles
eamodio.gitlens
GitHub.github-vscode-theme
mosapride.zenkaku
MS-CEINTL.vscode-language-pack-ja
streetsidesoftware.code-spell-checker
usernamehw.errorlens
vscode-icons-team.vscode-icons
yzhang.markdown-all-in-one
)
 
for var in ${pkglist[@]}
do
    code --install-extension $var
done