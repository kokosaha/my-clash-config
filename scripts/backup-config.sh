#!/usr/bin/env bash
# 备份 Clash 配置 Cures Cloud.yaml 到项目 backup/ 目录（带时间戳）

set -e

CONFIG_PATH="${HOME}/.config/clash/Cures Cloud.yaml"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${PROJECT_ROOT}/backup"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_NAME="Cures Cloud.yaml.bak.${TIMESTAMP}"

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "error: config not found: $CONFIG_PATH"
  exit 1
fi

mkdir -p "$BACKUP_DIR"
cp "$CONFIG_PATH" "${BACKUP_DIR}/${BACKUP_NAME}"
echo "${BACKUP_DIR}/${BACKUP_NAME}"
