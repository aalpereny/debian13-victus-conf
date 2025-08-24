#!/bin/bash

FLAG_FILE=".var/log/deb13_victus"
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
    local cmd="$*"
    doas bash -c "$cmd"
    local status=$?
    if [ $status -ne 0 ]; then
        echo -e "\n❌ HATA: Komut başarısız oldu: $cmd"
        echo "Çıkılıyor..."
        exit $status
    fi
    sleep 1
}

if [ -f "$FLAG_FILE" ]; then
    echo "🚫 Kurulum daha önce yapılmış."
    exit 0
fi

echo "📦 Derleme için gerekli paketler kuruluyor..."
run_cmd "apt install -y dkms git build-essential cmake libpci-dev linux-headers-$(uname -r)"

echo "🎮 NVIDIA sürücüleri kuruluyor..."
run_cmd "apt install -y nvidia-kernel-dkms nvidia-driver firmware-misc-nonfree"

echo "⚙️ ryzen_smu indiriliyor ve kuruluyor..."
if [ ! -d ryzen_smu ]; then
    git clone https://github.com/amkillam/ryzen_smu.git
fi
run_cmd "cd ryzen_smu && make dkms-install && cd .."

if [ ! -f /etc/modules-load.d/ryzen_smu.conf ]; then
    echo -e '# Load ryzen_smu driver upon startup\nryzen_smu' | doas tee /etc/modules-load.d/ryzen_smu.conf >/dev/null
fi
sleep 1

echo "⚙️ RyzenAdj indiriliyor ve derleniyor..."
if [ ! -d RyzenAdj ]; then
    git clone https://github.com/FlyGoat/RyzenAdj
fi
cd RyzenAdj && cmake -B build -DCMAKE_BUILD_TYPE=Release && make -C build -j$(nproc)
run_cmd "cp build/ryzenadj /usr/local/bin/"
cd ..

echo "⚙️ MangoHud indiriliyor ve kuruluyor..."
if [ ! -d MangoHud ]; then
    git clone --recurse-submodules https://github.com/flightlessmango/MangoHud.git
fi
run_cmd "cd MangoHud && ./build.sh build && ./build.sh install && cd .."

echo "✅ RyzenAdj için systemd servisi oluşturuluyor..."
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
sleep 1

clear
echo -e "🟢 Kurulum tamamlandı!"
doas touch "$FLAG_FILE"
