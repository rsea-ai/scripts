#!/bin/bash

# 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "❌ 请使用 root 权限执行此脚本 (sudo $0)"
  exit 1
fi

# 地区与镜像源映射
declare -A MIRRORS=(
    ["1"]="https://mirrors.xtom.hk"
    ["2"]="https://mirrors.xtom.us"
    ["3"]="https://mirrors.xtom.nl"
    ["4"]="https://mirrors.xtom.de"
    ["5"]="https://mirrors.xtom.ee"
    ["6"]="https://mirrors.xtom.jp"
    ["7"]="https://mirrors.xtom.au"
    ["8"]="https://mirrors.xtom.sg"
)

declare -A REGIONS=(
    ["1"]="Hong Kong, China"
    ["2"]="San Jose, CA"
    ["3"]="Amsterdam, The Netherlands"
    ["4"]="Düsseldorf, Germany"
    ["5"]="Tallinn, Estonia"
    ["6"]="Osaka, Japan"
    ["7"]="Sydney, Australia"
    ["8"]="Singapore"
)

echo "========================================="
echo "       xTom APT 镜像源一键配置脚本       "
echo "========================================="
echo "请选择服务器所在地区 / 目标镜像源："
for i in {1..8}; do
    echo "  $i) ${REGIONS[$i]}"
done

read -p "请输入数字 [1-8]: " REGION_CHOICE

if [[ -z "${MIRRORS[$REGION_CHOICE]}" ]]; then
    echo "❌ 无效的选择，脚本退出。"
    exit 1
fi

BASE_URL="${MIRRORS[$REGION_CHOICE]}"
echo "✅ 已选择镜像源: $BASE_URL"
echo "-----------------------------------------"

echo "请选择当前系统的版本："
echo "  1) Ubuntu 22.04 (Jammy)"
echo "  2) Ubuntu 24.04 (Noble) - DEB822 格式"
echo "  3) Debian 12 (Bookworm)"
echo "  4) Debian 13 (Trixie)"

read -p "请输入数字 [1-4]: " OS_CHOICE

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

case $OS_CHOICE in
    1)
        OS_TYPE="ubuntu"
        CODENAME="jammy"
        TARGET_FILE="/etc/apt/sources.list"
        ;;
    2)
        OS_TYPE="ubuntu24"
        CODENAME="noble"
        TARGET_FILE="/etc/apt/sources.list.d/ubuntu.sources"
        ;;
    3)
        OS_TYPE="debian"
        CODENAME="bookworm"
        TARGET_FILE="/etc/apt/sources.list"
        ;;
    4)
        OS_TYPE="debian"
        CODENAME="trixie"
        TARGET_FILE="/etc/apt/sources.list"
        ;;
    *)
        echo "❌ 无效的系统选择，脚本退出。"
        exit 1
        ;;
esac

echo "-----------------------------------------"

# 备份逻辑
if [ -f "$TARGET_FILE" ]; then
    cp "$TARGET_FILE" "${TARGET_FILE}.bak.${TIMESTAMP}"
    echo "📦 已备份原配置文件至: ${TARGET_FILE}.bak.${TIMESTAMP}"
else
    echo "⚠️ 未找到原配置文件，跳过备份直接创建..."
fi

# 针对 Ubuntu 24.04 从老版本升级上来的残留清理
if [ "$OS_CHOICE" -eq 2 ] && [ -f "/etc/apt/sources.list" ]; then
    mv /etc/apt/sources.list "/etc/apt/sources.list.disabled.${TIMESTAMP}"
    echo "📦 检测到遗留的 /etc/apt/sources.list，已将其重命名禁用。"
fi

# 写入新源
echo "✍️ 正在写入 xTom 镜像源配置..."

if [ "$OS_CHOICE" -eq 1 ]; then
cat > "$TARGET_FILE" <<EOF
deb $BASE_URL/ubuntu/ $CODENAME main restricted universe multiverse
deb $BASE_URL/ubuntu/ ${CODENAME}-updates main restricted universe multiverse
deb $BASE_URL/ubuntu/ ${CODENAME}-backports main restricted universe multiverse
deb $BASE_URL/ubuntu/ ${CODENAME}-security main restricted universe multiverse
EOF

elif [ "$OS_CHOICE" -eq 2 ]; then
mkdir -p /etc/apt/sources.list.d
cat > "$TARGET_FILE" <<EOF
Types: deb
URIs: $BASE_URL/ubuntu/
Suites: $CODENAME ${CODENAME}-updates ${CODENAME}-backports
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: $BASE_URL/ubuntu/
Suites: ${CODENAME}-security
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

elif [[ "$OS_CHOICE" -eq 3 || "$OS_CHOICE" -eq 4 ]]; then
cat > "$TARGET_FILE" <<EOF
deb $BASE_URL/debian/ $CODENAME main contrib non-free non-free-firmware
deb $BASE_URL/debian/ ${CODENAME}-updates main contrib non-free non-free-firmware
deb $BASE_URL/debian/ ${CODENAME}-backports main contrib non-free non-free-firmware
deb $BASE_URL/debian-security/ ${CODENAME}-security main contrib non-free non-free-firmware
EOF
fi

echo "🔄 配置已写入，正在执行 apt update 刷新缓存..."
apt-get update -y

echo "========================================="
echo "🎉 镜像源替换完成！系统现在使用 xTom 加速。"
echo "========================================="
