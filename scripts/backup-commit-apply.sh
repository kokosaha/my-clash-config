#!/usr/bin/env bash
# 1. 备份配置到 backup/（文件名含时间戳）
# 2. git add + commit，commit 消息描述该备份版本所含直连规则
# 3. 执行 apply-direct-rules 修改配置
# 使用方式：./scripts/backup-commit-apply.sh [commit-message]
# 若未传 commit-message，则根据是否已含直连规则自动生成。

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="${HOME}/.config/clash/Cures Cloud.yaml"
cd "$PROJECT_ROOT"

BACKUP_PATH=$(./scripts/backup-config.sh)
if [[ -z "$BACKUP_PATH" || ! -f "$BACKUP_PATH" ]]; then
  echo "error: backup failed or path missing"
  exit 1
fi

if [[ -n "$1" ]]; then
  COMMIT_MSG="$1"
else
  # 根据本次备份内容（刚备份的即当前配置）判断
  if grep -q "DOMAIN-SUFFIX,csrzic.com,DIRECT" "$BACKUP_PATH" 2>/dev/null; then
    COMMIT_MSG="chore(backup): 已包含中车/腾讯文档/腾讯会议/石墨/豆包直连规则"
  else
    COMMIT_MSG="chore(backup): 原始配置，未添加中车/腾讯文档/腾讯会议/石墨/豆包直连规则"
  fi
fi

if git rev-parse --is-inside-work-tree &>/dev/null; then
  git add "$BACKUP_PATH"
  if git diff --cached --quiet; then
    echo "无新备份变更，跳过 commit。"
  else
    git commit -m "$COMMIT_MSG"
    echo "已提交: $COMMIT_MSG"
  fi
else
  echo "提示: 非 git 仓库，已跳过 commit。请先 git init 后再运行以纳入版本管理。"
fi

./scripts/apply-direct-rules.sh
