#!/bin/bash

# 加载通用函数
[ -f "mods/common-functions.sh" ] && . mods/common-functions.sh

_mod_info "Starting i18n processing..."

I18N_DIR="$BASE_DIR/i18n"
PO_DIR="$I18N_DIR/po"
LMO_DIR="$I18N_DIR/lmo"
PO2LMO_SRC_DIR="$I18N_DIR/po2lmo"
OUTPUT_DIR="$ROOT_DIR/usr/lib/lua/luci/i18n"

_mod_info "Cleaning previous LMO files"
mod_rm "$LMO_DIR"/*.lmo

_mod_info "Creating necessary directories"
mod_mkdir "$LMO_DIR"
mod_mkdir "$OUTPUT_DIR"

for po_file in "$PO_DIR"/*.po; do
    if [ -f "$po_file" ] && ! grep -Pq '\.en\.po$' <<< "$po_file"; then
        po_filename=$(basename "$po_file" .po)
        lmo_file="$LMO_DIR/$po_filename.lmo"
        _mod_info "Compiling $po_file to $lmo_file"
        run_cmd "$TOOLS_DIR/po2lmo.py" "$po_file" "$lmo_file"
    fi
done

_mod_info "Copying LMO files to output directory"
mod_mkdir "$OUTPUT_DIR"
mod_cp -f "$LMO_DIR"/*.lmo "$OUTPUT_DIR/"

_mod_info "i18n processing completed successfully"
