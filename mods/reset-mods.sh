#!/bin/bash

# 加载通用函数
[ -f "mods/common-functions.sh" ] && . mods/common-functions.sh

_mod_info "Starting reset modifications..."

_mod_info "Copying reset files to root directory"
mod_cp -a "files/reset/." "$ROOT_DIR/"

_mod_info "Reset modifications completed"
