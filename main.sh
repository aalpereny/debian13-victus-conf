#!/bin/bash
# BU KOD DIZISI CHATGPT YARDIMI ILE OLUSTURULMUSTUR!

TOTAL_STEPS=15
DRY_RUN=false
[ "$1" == "--dry-run" ] && DRY_RUN=true

clear

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
    if $DRY_RUN; then
        echo -e "\n(Simülasyon) $*"
        sleep 0.5
    else
        eval "$@"
    fi
}

run_step() {
    local step_num=$1
    local title="$2"
    draw_progress "$step_num" "$title"
}

# Başlangıç mesajı
if $DRY_RUN; then
    echo "🚀 [Simülasyon modu] Hiçbir değişiklik yapılmayacaktır."
else
    echo "🚀 Gerçek kurulum başlatılıyor..."
fi
sleep 1

run_step 0 "📝 [0/14] APT kaynakları güncelleniyor..."
run_cmd "true"

run_step 1 "🔄 [1/14] Paket listesi güncelleniyor..."
run_cmd "apt update"

run_step 2 "⬆️ [2/14] Sistem paketleri yükseltiliyor..."
run_cmd "apt upgrade -y"

run_step 3 "📦 [3/14] doas paketi kuruluyor..."
run_cmd "apt install -y doas"

run_step 4 "🛠️ [4/14] /etc/doas.conf yapılandırması yapılıyor..."
run_cmd "echo 'permit setenv {PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin} :wheel' >> /etc/doas.conf"
run_cmd "echo 'permit setenv { XAUTHORITY LANG LC_ALL } :wheel' >> /etc/doas.conf"

run_step 5 "🔒 [5/14] doas.conf dosya izinleri ayarlanıyor..."
run_cmd "chmod 0400 /etc/doas.conf && chown root:root /etc/doas.conf"

run_step 6 "✅ [6/14] doas yapılandırması kontrol ediliyor..."
run_cmd "doas -C /etc/doas.conf || echo '❌ yapılandırma hatası'"

run_step 7 "⏸️ [7/14] Devam etmek için kullanıcıdan onay alınıyor..."
if ! $DRY_RUN; then
    read -p $'\nDevam etmek için Enter tuşuna basın...'
fi

run_step 8 "🔁 [8/14] sudo yerine doas sembolik linki oluşturuluyor..."
run_cmd "mv /usr/bin/sudo /usr/bin/sudobak && ln -s \$(which doas) /usr/bin/sudo"

run_step 9 "📦 [9/14] Derleme için gerekli paketler kuruluyor..."
run_cmd "apt install -y dkms git build-essential cmake libpci-dev linux-headers-\$(uname -r)"

run_step 10 "🎮 [10/14] NVIDIA sürücüleri kuruluyor..."
run_cmd "apt install -y nvidia-kernel-dkms nvidia-driver firmware-misc-nonfree"

run_step 11 "⚙️ [11/14] ryzen_smu indiriliyor ve kuruluyor..."
run_cmd "git clone https://github.com/amkillam/ryzen_smu.git"
run_cmd "cd ryzen_smu && make dkms-install && cd .."
run_cmd "echo -e '# Load ryzen_smu driver upon startup\nryzen_smu' > /etc/modules-load.d/ryzen_smu.conf"

run_step 12 "⚙️ [12/14] RyzenAdj indiriliyor ve derleniyor..."
run_cmd "git clone https://github.com/FlyGoat/RyzenAdj"
run_cmd "cd RyzenAdj && cmake -B build -DCMAKE_BUILD_TYPE=Release && make -C build -j\$(nproc)"
run_cmd "cp build/ryzenadj /usr/local/bin/"
run_cmd "cd .."

run_step 13 "⚙️ [13/14] MangoHud indiriliyor ve kuruluyor..."
run_cmd "git clone --recurse-submodules https://github.com/flightlessmango/MangoHud.git"
run_cmd "cd MangoHud && ./build.sh build && ./build.sh install && cd .."

run_step 14 "✅ [14/14] RyzenAdj için systemd servisi oluşturuluyor..."
run_cmd "cat <<EOF > /etc/systemd/system/ryzenadj.service
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
run_cmd "systemctl enable ryzenadj.service"

echo -e "\n✅ Kurulum tamamlandı."
$DRY_RUN && echo "(Simülasyon modundaydınız, sistem değiştirilmedi.)"
