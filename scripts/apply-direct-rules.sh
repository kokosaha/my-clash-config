#!/usr/bin/env bash
# 在 Cures Cloud.yaml 的 tenpay.com 直连规则后插入 8 条直连规则（中车/腾讯文档/腾讯会议/石墨/豆包）
# 若已存在则跳过，避免重复插入。
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

if grep -q "DOMAIN-SUFFIX,csrzic.com,DIRECT" "$CONFIG_PATH"; then
  echo "直连规则已存在，跳过修改。"
  exit 0
fi

if [[ -n "$OUTPUT_PATH" ]]; then
  OUT_ABS="${PROJECT_ROOT}/${OUTPUT_PATH#/}"
  mkdir -p "$(dirname "$OUT_ABS")"
  sed "/- 'DOMAIN-SUFFIX,tenpay\.com,DIRECT'/r $RULES_FILE" "$CONFIG_PATH" > "$OUT_ABS"
  echo "已生成含直连规则的配置: $OUT_ABS"
  echo "请复制到 ~/.config/clash/Cures Cloud.yaml 并重载 Clash。"
else
  sed -i '' "/- 'DOMAIN-SUFFIX,tenpay\.com,DIRECT'/r $RULES_FILE" "$CONFIG_PATH"
  echo "已插入 8 条直连规则，请手动重载 Clash 配置。"
fi
