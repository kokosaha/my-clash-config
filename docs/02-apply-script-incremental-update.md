# apply-direct-rules.sh 增量追加功能方案

**创建时间**：2026-01-25  
**状态**：待实施  
**相关文件**：`scripts/apply-direct-rules.sh`、`scripts/rules-to-add.txt`

---

## 问题描述

当前 `apply-direct-rules.sh` 的逻辑：

```bash
if grep -q "DOMAIN-SUFFIX,csrzic.com,DIRECT" "$CONFIG_PATH"; then
  echo "直连规则已存在，跳过修改。"
  exit 0
fi
```

**问题**：只要检测到第一条规则（`csrzic.com`）存在，就**全部跳过**，导致：
- 用户无法在 `rules-to-add.txt` 中追加新规则后自动插入
- 必须手动编辑配置文件，或删除旧规则后重新运行脚本

---

## 目标

修改脚本，支持**增量追加**：
- 读取 `rules-to-add.txt` 的每一行规则
- 检查配置文件中是否已存在该规则
- **只插入不存在的规则**，已存在的跳过
- 保持 `rules-to-add.txt` 中的顺序

---

## 实现方案（方案 B）

### 思路

1. 读取 `rules-to-add.txt`，逐行检查
2. 从规则行提取域名，检查配置中是否已存在
3. 将不存在的规则收集到**临时文件**
4. 一次性在 `tenpay.com` 直连规则之后插入
5. **插入完成后清除临时文件**（正常退出或异常退出均需清理）

### 域名提取

从规则行 `    - 'DOMAIN-SUFFIX,csrzic.com,DIRECT'` 中提取 `csrzic.com`：

```bash
domain=$(echo "$rule_line" | sed -n "s/.*DOMAIN-SUFFIX,\([^,']*\),DIRECT.*/\1/p")
```

### 插入位置

统一在 `- 'DOMAIN-SUFFIX,tenpay.com,DIRECT'` 之后插入，使用 sed 的 `r` 命令将临时文件内容追加到该行之后。

### 代码结构

```bash
#!/usr/bin/env bash
# ... 现有参数解析、CONFIG_PATH、RULES_FILE、OUTPUT_PATH 等 ...

# 检查并收集新规则
TEMP_RULES=$(mktemp)
trap 'rm -f "$TEMP_RULES"' EXIT

NEW_COUNT=0

while IFS= read -r rule_line || [[ -n "$rule_line" ]]; do
  [[ -z "$rule_line" || "$rule_line" =~ ^[[:space:]]*# ]] && continue

  domain=$(echo "$rule_line" | sed -n "s/.*DOMAIN-SUFFIX,\([^,']*\),DIRECT.*/\1/p")
  [[ -z "$domain" ]] && continue

  if ! grep -q "DOMAIN-SUFFIX,$domain,DIRECT" "$CONFIG_PATH"; then
    echo "$rule_line" >> "$TEMP_RULES"
    ((NEW_COUNT++))
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
```

### 临时文件清理

- 使用 `trap 'rm -f "$TEMP_RULES"' EXIT`：脚本**无论正常结束还是中途报错退出**，都会在退出时删除临时文件，无需在末尾或其他分支再写 `rm -f`。

### 要点小结

1. **逐行检查**：每条规则独立判断是否存在
2. **批量插入**：收集到临时文件后一次性插入，避免多次改写配置
3. **临时文件必清**：用 `trap ... EXIT` 保证临时文件始终被删除
4. **统计输出**：输出本次新插入的规则数量
5. **兼容 `--output`**：保持写入项目内文件的模式

---

## 测试场景

1. **首次运行**：配置中无规则 → 插入全部 8 条
2. **增量追加**：配置中已有 8 条，`rules-to-add.txt` 追加 2 条 → 只插入 2 条
3. **重复运行**：配置中已有全部规则 → 输出「所有规则已存在」
4. **部分存在**：配置中有 5 条，`rules-to-add.txt` 有 8 条 → 插入 3 条

---

## 注意事项

1. **规则格式**：`rules-to-add.txt` 每行须为 `    - 'DOMAIN-SUFFIX,域名,DIRECT'`（含 4 空格缩进）
2. **插入位置**：统一在 `tenpay.com` 之后，新规则按 `rules-to-add.txt` 顺序插入
3. **已存在规则**：若配置中已有规则但不在 `tenpay.com` 之后，脚本仍会在 `tenpay.com` 之后追加，可能重复，需手动去重

---

## 后续优化（可选）

- **去重检查**：扫描整个配置文件，不仅检查 `tenpay.com` 附近
- **位置调整**：将已存在规则挪到 `tenpay.com` 之后，保持集中
- **规则验证**：校验 `rules-to-add.txt` 格式，提前报错
