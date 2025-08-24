#!/bin/bash

FLAG_FILE="/var/log/deb13_victus"

if [ -f "$FLAG_FILE" ]; then
    echo "🚫 Kurulum daha önce yapılmış."
    exit 0
fi

echo "🚀 Kurulum başlıyor..."

# Root işlemlerini su -c ile yapıyoruz
su -c "
    set -e
    echo '📝 APT kaynakları güncelleniyor...'
    grep -q 'contrib non-free non-free-firmware' /etc/apt/sources.list || \
    sed -i 's|^deb http://deb.debian.org/debian/ trixie main non-free-firmware\$|deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware|' /etc/apt/sources.list

    grep -q 'contrib non-free non-free-firmware' /etc/apt/sources.list || \
    sed -i 's|^deb http://security.debian.org/debian-security trixie-security main  non-free-firmware\$|deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware|' /etc/apt/sources.list

    echo '🔄 Paket listesi güncelleniyor...'
    apt update

    echo '⬆️ Sistem paketleri yükseltiliyor...'
    apt upgrade -y

    echo '📦 doas kuruluyor...'
    dpkg -s doas &>/dev/null || apt install -y doas

    echo '🛠️ /etc/doas.conf yapılandırması yapılıyor...'
    NORMAL_USER=\"$USER\"
    grep -q \"permit setenv {PATH=\" /etc/doas.conf || echo \"permit setenv {PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin} \$NORMAL_USER\" >> /etc/doas.conf
    grep -q \"permit setenv { XAUTHORITY LANG LC_ALL } \$NORMAL_USER\" /etc/doas.conf || echo \"permit setenv { XAUTHORITY LANG LC_ALL } \$NORMAL_USER\" >> /etc/doas.conf

    echo '🔒 doas.conf dosya izinleri ayarlanıyor...'
    chmod 0400 /etc/doas.conf && chown root:root /etc/doas.conf

    echo '✅ doas yapılandırması kontrol ediliyor...'
    doas -C /etc/doas.conf

    echo '🔁 sudo yerine doas sembolik linki oluşturuluyor...'
    if [ ! -L /usr/bin/sudo ]; then
        mv /usr/bin/sudo /usr/bin/sudobak
        ln -s \$(which doas) /usr/bin/sudo
    fi
"

if [ $? -ne 0 ]; then
    echo "❌ Root işlemlerinde hata oluştu, çıkılıyor."
    exit 1
fi

echo "👤 Root işlemleri tamamlandı. Şimdi normal kullanıcı işlemlerine geçiliyor..."

# Normal kullanıcı olarak ikinci scripti çalıştırıyoruz
bash ./post_install.sh

