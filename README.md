# my-clash-config

Clash 直连规则方案归档与执行脚本。

## 目录结构

```
my-clash-config/
├── README.md              # 本说明
├── docs/
│   └── plan-clash-direct-rules.md   # 直连规则方案全文
├── rules/
│   └── direct-rules.yaml            # 待插入的 8 条 DIRECT 规则（YAML 片段）
├── scripts/
│   ├── backup-config.sh             # 备份配置到 backup/（文件名含 2026-01-25_16-35-48 式时间戳）
│   ├── backup-commit-apply.sh       # 备份 → git commit → 应用规则（一键流程）
│   ├── apply-direct-rules.sh        # 在 tenpay.com 后插入 8 条直连规则，已存在则跳过
│   ├── test-direct.sh               # 连通性 curl + 日志直连检查
│   └── rules-to-add.txt             # 规则纯文本（含缩进），供 apply 脚本使用
└── backup/                          # 配置备份归档（纳入 git，便于从历史 commit 查看直连规则版本）
```

## 快速使用

1. **备份 + 提交 + 应用规则（推荐）**  
   ```bash
   git init   # 首次使用在本项目下执行
   ./scripts/backup-commit-apply.sh
   ```  
   - 备份 `~/.config/clash/Cures Cloud.yaml` 到 `backup/Cures Cloud.yaml.bak.<日期_时间>`  
   - 若为 git 仓库，则 `git add` 该备份并 `git commit`，消息会标明该版本是否已含直连规则（如「原始配置，未添加…」或「已包含…直连规则」）  
   - 随后执行 `apply-direct-rules.sh`，在配置中插入 8 条直连规则（已存在则跳过）  
   - **执行完成后，请手动在 Clash 中重载配置。**

2. **仅备份**  
   ```bash
   ./scripts/backup-config.sh
   ```

3. **仅应用规则**  
   ```bash
   ./scripts/apply-direct-rules.sh
   ```  
   修改完成后手动重载 Clash。

4. **验证直连**  
   访问方案中的各链接（或先跑一遍 curl），再执行：  
   ```bash
   ./scripts/test-direct.sh
   ```  
   脚本会经 `127.0.0.1:7890` 做连通性测试，并在 `~/Library/Logs/ClashX Pro/`（或 ClashX）最新日志中检查相关域名是否 `proxy=DIRECT`。

## 方案与日志

- 方案说明、规则列表、修改位置、验证步骤：见 [docs/plan-clash-direct-rules.md](docs/plan-clash-direct-rules.md)。
- Clash 日志路径：ClashX Pro → `~/Library/Logs/ClashX Pro/`；ClashX → `~/Library/Logs/ClashX/`。当前生效日志 = 该目录下修改时间最新的 `.log`。

## 依赖

- `bash`、`curl`
- Clash 已运行且 `mixed-port: 7890`，使用 ClashX Pro 或 ClashX。

## Git 推送 GitHub

Git 默认**不使用系统代理**，直连 `github.com` 在国内易超时（如 `Failed to connect to github.com port 443`）。让 Git 访问 GitHub 时走 Clash（`http.https://github.com.proxy`）即可：

```bash
git config --global http.https://github.com.proxy http://127.0.0.1:7890
git config --global https.https://github.com.proxy https://127.0.0.1:7890
```

以上为**永久**生效（写入 `~/.gitconfig`）。取消代理：`git config --global --unset http.https://github.com.proxy` 及 `https.https://github.com.proxy`。
