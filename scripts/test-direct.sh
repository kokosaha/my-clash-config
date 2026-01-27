#!/usr/bin/env bash
# 直连验证：经 Clash 代理 curl 各 URL，再在 Clash 日志中检查是否 proxy=DIRECT

set -e

PROXY="http://127.0.0.1:7890"
LOG_DIR_CLASHX_PRO="${HOME}/Library/Logs/ClashX Pro"
LOG_DIR_CLASHX="${HOME}/Library/Logs/ClashX"
URLS=(
  "https://cmail.csrzic.com/"
  "https://foreseesolar.csrzic.com/"
  "https://docs.qq.com/"
  "https://meeting.tencent.com/"
  "https://shimo.im/"
  "https://www.doubao.com/"
  "https://weixin.qq.com/"
  "https://wechat.com/"
  "https://docker.1ms.run/"
  "https://dockerproxy.cn/"
  "https://docker.mirrors.ustc.edu.cn/"
  "https://hub-mirror.c.163.com/"
  "https://docker.nju.edu.cn/"
  "https://www.isolarcloud.com/"
)
DOMAINS=( "csrzic.com" "docs.qq.com" "meeting.tencent.com" "meeting.qq.com" "wemeet.qq.com" "wemeet.tencent.com" "shimo.im" "doubao.com" "wechat.com" "wechatpay.cn" "wechatpay.com" "wechatapp.com" "wechatos.net" "weixin.qq.com" "weixin.com" "servicewechat.com" "wx.qq.com" "wxs.qq.com" "weixinconf.qq.com" "qpic.cn" "qlogo.cn" "wx.gtimg.com" "scdsjzx.com" "xdow.net" "1ms.run" "dockerproxy.cn" "mirrors.ustc.edu.cn" "c.163.com" "nju.edu.cn" "isolarcloud.com" )

echo "==> 连通性测试（经代理 ${PROXY}）"
for u in "${URLS[@]}"; do
  code=$(curl -sS -x "$PROXY" -o /dev/null -w '%{http_code}' --connect-timeout 10 "$u" 2>/dev/null || echo "000")
  echo "  ${u} -> HTTP ${code}"
done

echo ""
echo "==> 日志直连检查"

if [[ -d "$LOG_DIR_CLASHX_PRO" ]]; then
  LOG_DIR="$LOG_DIR_CLASHX_PRO"
elif [[ -d "$LOG_DIR_CLASHX" ]]; then
  LOG_DIR="$LOG_DIR_CLASHX"
else
  echo "  error: ClashX Pro / ClashX 日志目录未找到"
  exit 1
fi

LATEST=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)
if [[ -z "$LATEST" || ! -f "$LATEST" ]]; then
  echo "  error: 未找到最新 .log 文件 in $LOG_DIR"
  exit 1
fi

echo "  使用日志: $LATEST"
for d in "${DOMAINS[@]}"; do
  count=$(grep -c "rAddr=.*${d}" "$LATEST" 2>/dev/null || true)
  direct=$(grep "rAddr=.*${d}" "$LATEST" 2>/dev/null | grep -c "proxy=DIRECT" || true)
  if [[ "$count" -gt 0 ]]; then
    if [[ "$direct" -eq "$count" ]]; then
      echo "  [OK] ${d}: ${direct}/${count} DIRECT"
    else
      echo "  [!!] ${d}: ${direct}/${count} DIRECT (存在非直连)"
    fi
  else
    echo "  [--] ${d}: 无连接记录（请先访问对应链接后再运行）"
  fi
done
