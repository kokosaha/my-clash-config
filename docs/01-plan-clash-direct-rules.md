# Clash 直连规则添加与测试

在 Clash 配置文件 `Cures Cloud.yaml` 的 rules 中新增 5 类网站（中车、腾讯文档、腾讯会议、石墨文档、豆包）的直连（DIRECT）规则，并验证配置语法、连通性及日志中的直连策略。

---

## 配置文件与规则结构

- **配置文件路径**：`~/.config/clash/Cures Cloud.yaml`
- **规则格式**：`TYPE,MATCH,POLICY`，直连使用 `DIRECT`
- **规则顺序**：自上而下匹配，先匹配先生效。现有大量 `DIRECT` 规则（如 `qq.com`、`tencent.com`）位于约 82–174 行，末尾为 `GEOIP,CN,DIRECT` 和 `MATCH,Cures Cloud`

## 需添加的直连规则

在 **rules** 中新增以下 `DIRECT` 规则（建议放在现有国内直连规则块内，例如 `tenpay.com` 直连规则之后、`rarbg.to` 之前，约 164 行附近），保证优先于后续代理规则匹配：

| 类别 | 规则 | 说明 |
|------|------|------|
| 1. 中车 | `DOMAIN-SUFFIX,csrzic.com,DIRECT` | 覆盖 cmail.csrzic.com、foreseesolar.csrzic.com |
| 2. 腾讯文档 | `DOMAIN-SUFFIX,docs.qq.com,DIRECT` | 覆盖 docs.qq.com 及其子域 |
| 3. 腾讯会议 | `DOMAIN-SUFFIX,meeting.tencent.com,DIRECT` | 官网、下载等 |
| | `DOMAIN-SUFFIX,meeting.qq.com,DIRECT` | 备用官网 |
| | `DOMAIN-SUFFIX,wemeet.qq.com,DIRECT` | 官网及信令等 |
| | `DOMAIN-SUFFIX,wemeet.tencent.com,DIRECT` | 信令等子域 |
| 4. 石墨文档 | `DOMAIN-SUFFIX,shimo.im,DIRECT` | 覆盖 shimo.im 及子域 |
| 5. 豆包 | `DOMAIN-SUFFIX,doubao.com,DIRECT` | 豆包主站及子域 |

**说明**：配置中已有 `qq.com`、`tencent.com` 的 `DIRECT`，理论上 `docs.qq.com`、`meeting.tencent.com` 等已直连。显式添加上述规则可确保会议/文档相关子域明确走直连，且便于后续单独调整。

## 具体修改位置

在 `rules:` 列表中，于 `- 'DOMAIN-SUFFIX,tenpay.com,DIRECT'` 之后插入上述 8 条规则，保持 YAML 缩进与现有规则一致。规则片段见 `../rules/direct-rules.yaml`，亦可从 `../scripts/rules-to-add.txt` 复制。

## Clash 日志文件位置

| 客户端 | 日志目录 | 文件示例 |
|--------|----------|----------|
| **ClashX Pro** | `~/Library/Logs/ClashX Pro/` | `com.west2online.ClashXPro 2026-01-24--03-57-34-789.log` |
| **ClashX** | `~/Library/Logs/ClashX/` | `com.west2online.ClashX 2026-01-24--08-41-30-540.log` |

每次启动客户端会生成新日志，**当前生效的日志** = 该目录下**修改时间最新**的 `.log` 文件。

日志每行格式示例：`[TCP] connected ... rAddr=域名:端口 ... rule=... proxy=DIRECT` 或 `proxy=Cures Cloud[...]`。用 `proxy=DIRECT` 判断该连接为直连。

## 验证与测试

1. **语法与加载**：修改后检查 YAML 语法，在 Clash 中重载配置（或重启），确认无报错、规则列表含新增条目。
2. **连通性测试**：Clash `mixed-port: 7890`，对方案中的各 URL 执行 `curl -x http://127.0.0.1:7890 -sI -o /dev/null -w '%{http_code}\n' <URL>`，确认返回 200/301/302 等。
3. **在日志中检查直连（必做）**：打开当前生效的日志，搜索 `csrzic.com`、`docs.qq.com`、`meeting.tencent.com`、`wemeet.qq.com`、`shimo.im`、`doubao.com`，确认对应行均为 `proxy=DIRECT`。

## 注意事项

- 仅修改 `rules`，不改动 `proxies`、`proxy-groups`、`dns` 等。
- 修改前务必备份 `Cures Cloud.yaml`。备份存放于 `backup/`，文件名含时间戳（如 `Cures Cloud.yaml.bak.2026-01-25_16-35-48`），便于归档；每次归档后执行 `git commit`，commit 消息标明该备份是否已含直连规则，便于从 git 历史查看各版本。

## 执行步骤摘要

1. **备份并纳入 git**：运行 `./scripts/backup-config.sh`，或将 `./scripts/backup-commit-apply.sh` 与 git 配合使用（备份 → `git add` + `git commit` → 应用规则）。commit 消息示例：`chore(backup): 原始配置，未添加…` / `chore(backup): 已包含…直连规则`。
2. **应用规则**：运行 `./scripts/apply-direct-rules.sh`（在 `tenpay.com` 后插入 8 条，已存在则跳过），或手动从 `rules/direct-rules.yaml` 插入。
3. **手动重载 Clash**：在 Clash 中重载配置。
4. 使用 `curl` 经 `127.0.0.1:7890` 请求各 URL，或运行 `./scripts/test-direct.sh`。
5. 到日志中检查直连是否成功，或由 `test-direct.sh` 辅助完成。
