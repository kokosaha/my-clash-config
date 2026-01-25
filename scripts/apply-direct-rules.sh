#!/usr/bin/env bash
# 在 Cures Cloud.yaml 的 tenpay.com 直连规则后插入直连规则（来源 rules-to-add.txt）
# 逐条检查，只插入不存在的规则；已存在则跳过。支持增量追加。
# 用法：./apply-direct-rules.sh [--output PATH]
#   --output PATH  将结果写入项目内 PATH，不修改 ~/.config/clash（用于无法写系统目录时）。

set -e

CONFIG_PATH="${HOME}/.config/clash/Cures Cloud.yaml"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RULES_FILE="${PROJECT_ROOT}/scripts/rules-to-add.txt"
OUTPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUTPUT_PATH="$2"; shift 2 ;;
    *) echo "error: unknown option $1"; exit 1 ;;
  esac
done

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "error: config not found: $CONFIG_PATH"
  exit 1
fi
if [[ ! -f "$RULES_FILE" ]]; then
  echo "error: rules file not found: $RULES_FILE"
  exit 1
fi

TEMP_RULES=$(mktemp)
trap 'rm -f "$TEMP_RULES"' EXIT

NEW_COUNT=0

while IFS= read -r rule_line || [[ -n "$rule_line" ]]; do
  [[ -z "$rule_line" || "$rule_line" =~ ^[[:space:]]*# ]] && continue

  domain=$(echo "$rule_line" | sed -n "s/.*DOMAIN-SUFFIX,\([^,']*\),DIRECT.*/\1/p")
  [[ -z "$domain" ]] && continue

  if ! grep -q "DOMAIN-SUFFIX,$domain,DIRECT" "$CONFIG_PATH"; then
    echo "$rule_line" >> "$TEMP_RULES"
    ((NEW_COUNT++)) || true
  fi
done < "$RULES_FILE"

if [[ $NEW_COUNT -gt 0 ]]; then
  if [[ -n "$OUTPUT_PATH" ]]; then
    OUT_ABS="${PROJECT_ROOT}/${OUTPUT_PATH#/}"
    mkdir -p "$(dirname "$OUT_ABS")"
    sed "/- 'DOMAIN-SUFFIX,tenpay\.com,DIRECT'/r $TEMP_RULES" "$CONFIG_PATH" > "$OUT_ABS"
    echo "已生成含 $NEW_COUNT 条新直连规则的配置: $OUT_ABS"
    echo "请复制到 ~/.config/clash/Cures Cloud.yaml 并重载 Clash。"
  else
    sed -i '' "/- 'DOMAIN-SUFFIX,tenpay\.com,DIRECT'/r $TEMP_RULES" "$CONFIG_PATH"
    echo "已插入 $NEW_COUNT 条新直连规则，请手动重载 Clash 配置。"
  fi
else
  echo "所有规则已存在，无需修改。"
fi
