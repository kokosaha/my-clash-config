# my-clash-config

Clash 直连规则方案归档与执行脚本。支持中车、腾讯文档/会议、石墨、豆包、微信等域名直连，规则可增量追加。

---

## 目录结构

```
my-clash-config/
├── README.md                 # 本说明
├── .gitignore
├── docs/                     # 方案与文档（按序号命名，便于追溯变更顺序）
│   ├── 00-docs-structure.md           # docs 目录结构说明与维护原则
│   ├── 01-plan-clash-direct-rules.md  # 直连规则方案（规则列表、插入位置、验证步骤）
│   └── 02-apply-script-incremental-update.md  # apply 脚本增量追加方案（B 方案）
├── rules/
│   └── direct-rules.yaml     # 直连规则 YAML 片段（参考用，与 rules-to-add.txt 对应）
├── scripts/
│   ├── backup-config.sh      # 备份 ~/.config/clash/Cures Cloud.yaml → backup/
│   ├── backup-commit-apply.sh # 备份 → git commit → 应用规则（一键流程）
│   ├── apply-direct-rules.sh # 按 rules-to-add.txt 增量插入直连规则
│   ├── test-direct.sh        # 连通性 curl + Clash 日志直连检查
│   └── rules-to-add.txt      # 待插入规则列表（供 apply 脚本读取，可追加）
├── backup/                   # 配置备份归档（纳入 git，commit 消息标明代际）
│   ├── .gitkeep
│   └── Cures Cloud.yaml.bak.<YYYY-MM-DD_HH-MM-SS>  # 带时间戳，便于排序
└── patched/                  # apply --output 时生成的含直连规则配置
    └── Cures Cloud.yaml      # 可复制到 ~/.config/clash/ 使用
```

---

## 各脚本功能

| 脚本 | 功能 |
|------|------|
| **backup-config.sh** | 将 `~/.config/clash/Cures Cloud.yaml` 复制到 `backup/`，文件名 `Cures Cloud.yaml.bak.<YYYY-MM-DD_HH-MM-SS>`，仅输出备份路径。 |
| **backup-commit-apply.sh** | ① 调用 `backup-config.sh` 备份；② 若为 git 仓库则 `git add` 该备份并 `git commit`（消息根据备份内容自动区分为「原始配置，未添加…直连规则」或「已包含…直连规则」）；③ 执行 `apply-direct-rules.sh`。可选参数：`[commit-message]` 覆盖自动生成的 commit 消息。 |
| **apply-direct-rules.sh** | 读取 `scripts/rules-to-add.txt`，逐条检查配置中是否已存在该规则；**仅插入不存在的规则**（增量追加）。插入位置：`tenpay.com` 直连规则之后。支持 `--output PATH`：将结果写入项目内 `PATH`（如 `patched/Cures Cloud.yaml`），不修改 `~/.config/clash/`，适用于无写权限环境。 |
| **test-direct.sh** | ① **连通性**：经 `http://127.0.0.1:7890` 代理 curl 预设 URL（中车、腾讯文档/会议、石墨、豆包、微信等）；② **日志直连检查**：在 `~/Library/Logs/ClashX Pro/`（或 ClashX）最新 `.log` 中统计各域名连接数及 `proxy=DIRECT` 数量，输出 `[OK]` / `[!!]` / `[--]`。直连是否成功以日志统计为准。 |
| **rules-to-add.txt** | 每行一条 `DOMAIN-SUFFIX,<域名>,DIRECT` 规则（含 4 空格缩进）。**追加新直连**：在此文件末尾追加新行，再运行 `apply-direct-rules.sh` 即可，已存在的规则不会重复插入。 |

---

## 快速使用

1. **备份 + 提交 + 应用规则（推荐）**  
   ```bash
   git init   # 首次使用
   ./scripts/backup-commit-apply.sh
   ```  
   执行完成后**手动在 Clash 中重载配置**。

2. **仅备份**  
   ```bash
   ./scripts/backup-config.sh
   ```

3. **仅应用规则**  
   - **直接改配置**（有写 `~/.config/clash/` 权限时）：  
     ```bash
     ./scripts/apply-direct-rules.sh
     ```  
   - **输出到项目再复制**（无写权限或只想先生成文件时）：  
     ```bash
     ./scripts/apply-direct-rules.sh --output patched/Cures\ Cloud.yaml
     cp "patched/Cures Cloud.yaml" ~/.config/clash/Cures\ Cloud.yaml
     ```  
     生成后**手动重载 Clash**。

4. **验证直连**  
   访问各直连链接后执行：  
   ```bash
   ./scripts/test-direct.sh
   ```

---

## 方案与日志

- 方案说明、规则列表、修改位置、验证步骤：见 [docs/01-plan-clash-direct-rules.md](docs/01-plan-clash-direct-rules.md)。
- apply 增量追加方案：见 [docs/02-apply-script-incremental-update.md](docs/02-apply-script-incremental-update.md)。
- **Clash 日志**：ClashX Pro → `~/Library/Logs/ClashX Pro/`；ClashX → `~/Library/Logs/ClashX/`。当前生效日志 = 该目录下修改时间最新的 `.log`。

---

## 依赖

- `bash`、`curl`
- Clash 已运行且 `mixed-port: 7890`，使用 ClashX Pro 或 ClashX。

---

## Git 推送 GitHub

Git 默认**不使用系统代理**，直连 `github.com` 在国内易超时。让 Git 访问 GitHub 时走 Clash：

```bash
git config --global http.https://github.com.proxy http://127.0.0.1:7890
git config --global https.https://github.com.proxy https://127.0.0.1:7890
```

以上为**永久**生效（写入 `~/.gitconfig`）。取消：`git config --global --unset http.https://github.com.proxy` 及 `https.https://github.com.proxy`。
