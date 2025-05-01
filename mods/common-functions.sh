#!/bin/bash

# 如果父脚本没有定义VERBOSE变量，在此设置默认值
if [ -z "$VERBOSE" ]; then
    VERBOSE=${VERBOSE:-false}
fi

# 输出调试信息的函数
_mod_info() {
    if [ "$VERBOSE" = true ]; then
        echo "[INFO] $1"
    fi
}

# 输出错误信息的函数
_mod_error() {
    echo "[ERROR] $1" >&2
    return 1
}

# 显示执行命令的包装函数
run_cmd() {
    local cmd="$*"
    if [ "$VERBOSE" = true ]; then
        echo "+ $cmd"
        eval "$cmd"
    else
        eval "$cmd" > /dev/null 2>&1
    fi
    return $?
}

# 带输出的复制函数
mod_cp() {
    if [ "$VERBOSE" = true ]; then
        cp -v "$@"
    else
        cp "$@"
    fi
}

# 带输出的删除函数
mod_rm() {
    if [ "$VERBOSE" = true ]; then
        rm -v "$@"
    else
        rm "$@"
    fi
}

# 带输出的符号链接函数
mod_ln() {
    if [ "$VERBOSE" = true ]; then
        ln -v "$@"
    else
        ln "$@"
    fi
}

# 带输出的mkdir函数
mod_mkdir() {
    if [ "$VERBOSE" = true ]; then
        mkdir -v "$@"
    else
        mkdir "$@"
    fi
}

# 文件修改函数，显示更多信息
mod_file_change() {
    local file="$1"
    local action="$2"
    local info="$3"
    
    echo "Modifying '$file': $action"
    _mod_info "$info"
}

# 二进制文件补丁函数
binary_patch() {
    local file="$1"
    local offset="$2"
    local data="$3"
    local description="$4"
    local count=${#data}
    
    if [ "$VERBOSE" = true ]; then
        echo "Patching '$file' at offset 0x$(printf '%X' $offset) with $count bytes: $description"
        { echo -n "$data"; cat /dev/zero; } | dd of="$file" conv=notrunc seek="$offset" bs=1 count="$count" 2>&1
    else
        { echo -n "$data"; cat /dev/zero; } | dd of="$file" conv=notrunc seek="$offset" bs=1 count="$count" 2>/dev/null
    fi
}

# 文件备份函数
backup_file() {
    local file="$1"
    local backup="${file}.bak"
    
    if [ ! -f "$backup" ]; then
        _mod_info "Creating backup of $file to $backup"
        cp -a "$file" "$backup"
    else
        _mod_info "Backup $backup already exists, skipping"
    fi
}

# 显示文件的十六进制转储
hex_dump() {
    if [ "$VERBOSE" = true ]; then
        local file="$1"
        local offset="$2"
        local count="${3:-16}"
        
        echo "Hex dump of $file at offset 0x$(printf '%X' $offset) ($count bytes):"
        dd if="$file" bs=1 skip="$offset" count="$count" 2>/dev/null | xxd
    fi
}

# 函数用于显示文件大小
file_size() {
    local file="$1"
    local size=$(stat -c '%s' "$file" 2>/dev/null)
    if [ $? -eq 0 ]; then
        _mod_info "Size of $file: $size bytes"
        echo "$size"
    else
        _mod_error "Failed to get size of $file"
        echo "0"
    fi
}

# 函数用于显示目录大小
dir_size() {
    local dir="$1"
    if [ "$VERBOSE" = true ]; then
        du -sh "$dir" 2>/dev/null
    fi
}

# 显示文件是否存在
file_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        _mod_info "File exists: $file"
        return 0
    else
        _mod_info "File does not exist: $file"
        return 1
    fi
}

# 显示目录是否存在
dir_exists() {
    local dir="$1"
    if [ -d "$dir" ]; then
        _mod_info "Directory exists: $dir"
        return 0
    else
        _mod_info "Directory does not exist: $dir"
        return 1
    fi
} 