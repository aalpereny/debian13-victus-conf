#!/bin/bash

FLAG_FILE="/var/log/deb13_victus"

TOTAL_STEPS=15

draw_progress() {
    local step=$1
    local title="$2"
    local percent=$(( step * 100 / TOTAL_STEPS ))
    local filled=$(( percent / 10 ))
    local empty=$(( 10 - filled ))

    bar="["
    for ((i=0; i<filled; i++)); do bar+="#"; done
    for ((i=0; i<empty; i++)); do bar+="."; done
    bar+="]"

    clear
    echo -e "$title"
    echo -e "$bar $percent% tamamlandı"
}

run_cmd() {
    eval "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo -e "\n❌ HATA: Komut başarısız oldu: $*"
        echo "Çıkılıyor..."
        exit $status
    fi
    return $status
}

run_step() {
    local step_num=$1
    local title="$2"
    draw_progress "$step_num" "$title"
}

NORMAL_USER="${SUDO_USER:-$USER}"

if [[ "$1" == "" ]]; then
    # Başlangıç: normal kullanıcı -> root'a geçiş
    echo "🔒 Root yetkisi gerekiyor. Şifrenizi girin..."
    exec su -c "bash $0 root"
fi

if [[ "$1" == "root" ]]; then
    # Root işlemler burada

    if [ "$EUID" -ne 0 ]; then
        echo "Root olarak çalıştırılmalıdır."
        exit 1
    fi

    if [ -f "$FLAG_FILE" ]; then
        echo "🚫 Kurulum daha önce yapılmış. Script sonlandırılıyor."
        exit 0
    fi

    echo "🚀 Root işlemleri başlıyor..."
    sleep 1

    # 0 - APT kaynakları güncelleniyor
    run_step 0 "📝 [0/14] APT kaynakları güncelleniyor..."
    grep -q 'contrib non-free non-free-firmware' /etc/apt/sources.list || \
    run_cmd "sed -i 's|^deb http://deb.debian.org/debian/ trixie main non-free-firmware$|deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware|' /etc/apt/sources.list"
    grep -q 'contrib non-free non-free-firmware' /etc/apt/sources.list || \
    run_cmd "sed -i 's|^deb http://security.debian.org/debian-security trixie-security main  non-free-firmware$|deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware|' /etc/apt/sources.list"

    # 1 - Paket listesi güncelleniyor
    run_step 1 "🔄 [1/14] Paket listesi güncelleniyor..."
    run_cmd "apt update"

    # 2 - Sistem paketleri yükseltiliyor
    run_step 2 "⬆️ [2/14] Sistem paketleri yükseltiliyor..."
    run_cmd "apt upgrade -y"

    # 3 - doas paketi kuruluyor
    run_step 3 "📦 [3/14] doas paketi kuruluyor..."
    dpkg -s doas &>/dev/null || run_cmd "apt install -y doas"

    # 4 - /etc/doas.conf yapılandırması yapılıyor
    run_step 4 "🛠️ [4/14] /etc/doas.conf yapılandırması yapılıyor..."

    if ! grep -q "permit setenv {PATH=" /etc/doas.conf 2>/dev/null; then
        run_cmd "echo 'permit setenv {PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin} $NORMAL_USER' >> /etc/doas.conf"
    fi
    if ! grep -q "permit setenv { XAUTHORITY LANG LC_ALL } $NORMAL_USER" /etc/doas.conf 2>/dev/null; then
        run_cmd "echo 'permit setenv { XAUTHORITY LANG LC_ALL } $NORMAL_USER' >> /etc/doas.conf"
    fi

    # 5 - doas.conf dosya izinleri ayarlanıyor
    run_step 5 "🔒 [5/14] doas.conf dosya izinleri ayarlanıyor..."
    run_cmd "chmod 0400 /etc/doas.conf && chown root:root /etc/doas.conf"

    # 6 - doas yapılandırması kontrol ediliyor
    run_step 6 "✅ [6/14] doas yapılandırması kontrol ediliyor..."
    run_cmd "doas -C /etc/doas.conf || { echo '❌ yapılandırma hatası'; exit 1; }"

    # 7 - sudo yerine doas sembolik linki oluşturuluyor (onay kaldırıldı)
    run_step 7 "🔁 [7/14] sudo yerine doas sembolik linki oluşturuluyor..."
    if [ ! -L /usr/bin/sudo ]; then
        run_cmd "mv /usr/bin/sudo /usr/bin/sudobak"
        run_cmd "ln -s $(which doas) /usr/bin/sudo"
    fi

    echo -e "\n👤 Root işlemler tamamlandı, normal kullanıcıya geçiliyor..."

    # root işlemler bitti, normal kullanıcıya geçiş için scripti user param ile çağır
    exec sudo -u "$NORMAL_USER" bash "$0" user
fi

if [[ "$1" == "user" ]]; then
    # Normal kullanıcı tarafı
    if [ "$(id -u)" -eq 0 ]; then
        echo "Bu kısmı normal kullanıcı olarak çalıştırmalısınız."
        exit 1
    fi

    echo "🚀 Normal kullanıcı işlemleri başlıyor..."

    # run_cmd fonksiyonunu normal kullanıcı olarak çalıştırmak için doas ile çalıştırıyoruz
    run_cmd() {
        local cmd="$*"
        doas bash -c "$cmd"
        local status=$?
        if [ $status -ne 0 ]; then
            echo -e "\n❌ HATA: Komut başarısız oldu: $cmd"
            echo "Çıkılıyor..."
            exit $status
        fi
        return $status
    }

    run_step() {
        local step_num=$1
        local title="$2"
        draw_progress "$step_num" "$title"
    }

    # 8 - Derleme için gerekli paketler kuruluyor
    run_step 8 "📦 [8/14] Derleme için gerekli paketler kuruluyor..."
    run_cmd "apt install -y dkms git build-essential cmake libpci-dev linux-headers-$(uname -r)"

    # 9 - NVIDIA sürücüleri kuruluyor
    run_step 9 "🎮 [9/14] NVIDIA sürücüleri kuruluyor..."
    run_cmd "apt install -y nvidia-kernel-dkms nvidia-driver firmware-misc-nonfree"

    # 10 - ryzen_smu indiriliyor ve kuruluyor
    run_step 10 "⚙️ [10/14] ryzen_smu indiriliyor ve kuruluyor..."
    if [ ! -d ryzen_smu ]; then
        run_cmd "git clone https://github.com/amkillam/ryzen_smu.git"
    fi
    run_cmd "cd ryzen_smu && make dkms-install && cd .."

    if [ ! -f /etc/modules-load.d/ryzen_smu.conf ]; then
        echo -e '# Load ryzen_smu driver upon startup\nryzen_smu' | doas tee /etc/modules-load.d/ryzen_smu.conf >/dev/null
    fi

    # 11 - RyzenAdj indiriliyor ve derleniyor
    run_step 11 "⚙️ [11/14] RyzenAdj indiriliyor ve derleniyor..."
    if [ ! -d RyzenAdj ]; then
        run_cmd "git clone https://github.com/FlyGoat/RyzenAdj"
    fi
    run_cmd "cd RyzenAdj && cmake -B build -DCMAKE_BUILD_TYPE=Release && make -C build -j$(nproc)"
    run_cmd "doas cp build/ryzenadj /usr/local/bin/"
    run_cmd "cd .."

    # 12 - MangoHud indiriliyor ve kuruluyor
    run_step 12 "⚙️ [12/14] MangoHud indiriliyor ve kuruluyor..."
    if [ ! -d MangoHud ]; then
        run_cmd "git clone --recurse-submodules https://github.com/flightlessmango/MangoHud.git"
    fi
    run_cmd "cd MangoHud && ./build.sh build && doas ./build.sh install && cd .."

    # 13 - RyzenAdj için systemd servisi oluşturuluyor
    run_step 13 "✅ [13/14] RyzenAdj için systemd servisi oluşturuluyor..."
    if [ ! -f /etc/systemd/system/ryzenadj.service ]; then
        doas bash -c "cat <<EOF > /etc/systemd/system/ryzenadj.service
[Unit]
Description=Set Ryzen power limits using RyzenAdj
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ryzenadj --stapm-limit=25000 --fast-limit=25000 --slow-limit=25000 --tctl-temp=70
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF"
        doas systemctl enable ryzenadj.service
    fi

    clear
    echo -e "🟢 [14/14] Kurulum tamamlandı!"
    echo "[##########] 100% Tamamlandı"

    doas touch "$FLAG_FILE"
fi
