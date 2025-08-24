#!/bin/bash

FLAG_FILE=".var/log/deb13_victus"

if [ -f "$FLAG_FILE" ]; then
    echo "🚫 Kurulum daha önce yapılmış."
    exit 0
fi

echo "🚀 Kurulum başlıyor..."

su -c "
    set -e
    echo '📝 APT kaynakları güncelleniyor...'
    grep -q 'contrib non-free non-free-firmware' /etc/apt/sources.list || \
    sed -i 's|^deb http://deb.debian.org/debian/ trixie main non-free-firmware\$|deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware|' /etc/apt/sources.list
    sleep 1

    grep -q 'contrib non-free non-free-firmware' /etc/apt/sources.list || \
    sed -i 's|^deb http://security.debian.org/debian-security trixie-security main  non-free-firmware\$|deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware|' /etc/apt/sources.list
    sleep 1

    echo '🔄 Paket listesi güncelleniyor...'
    apt update
    sleep 1

    echo '⬆️ Sistem paketleri yükseltiliyor...'
    apt upgrade -y
    sleep 1

    echo '📦 doas kuruluyor...'
    dpkg -s doas &>/dev/null || apt install -y doas
    sleep 1

    echo '🛠️ /etc/doas.conf yapılandırması yapılıyor...'
    NORMAL_USER=\"$USER\"
    grep -q \"permit setenv {PATH=\" /etc/doas.conf || echo \"permit setenv {PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin} \$NORMAL_USER\" >> /etc/doas.conf
    grep -q \"permit setenv { XAUTHORITY LANG LC_ALL } \$NORMAL_USER\" /etc/doas.conf || echo \"permit setenv { XAUTHORITY LANG LC_ALL } \$NORMAL_USER\" >> /etc/doas.conf
    sleep 1

    echo '🔒 doas.conf dosya izinleri ayarlanıyor...'
    chmod 0400 /etc/doas.conf && chown root:root /etc/doas.conf
    sleep 1

    echo '✅ doas yapılandırması kontrol ediliyor...'
    doas -C /etc/doas.conf
    sleep 1

    echo '🔁 sudo yerine doas sembolik linki oluşturuluyor...'
    if [ ! -L /usr/bin/sudo ]; then
        mv /usr/bin/sudo /usr/bin/sudobak
        ln -s \$(which doas) /usr/bin/sudo
    fi
    sleep 1
"

if [ $? -ne 0 ]; then
    echo "❌ Root işlemlerinde hata oluştu, çıkılıyor."
    exit 1
fi

echo "👤 Root işlemleri tamamlandı. Şimdi normal kullanıcı işlemlerine geçiliyor..."

bash ./post_install.sh
