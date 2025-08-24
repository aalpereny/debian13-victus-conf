#!/bin/bash

echo "📝 [0/14] APT kaynakları güncelleniyor..."
sed -i 's|^deb http://deb.debian.org/debian/ trixie main non-free-firmware$|deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware|' /etc/apt/sources.list
sed -i 's|^deb http://security.debian.org/debian-security trixie-security main  non-free-firmware$|deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware|' /etc/apt/sources.list

echo "🔄 [1/14] Paket listesi güncelleniyor..."
apt update

echo "⬆️ [2/14] Sistem paketleri yükseltiliyor..."
apt upgrade -y

echo "📦 [3/14] doas paketi kuruluyor..."
apt install -y doas

echo "🛠️ [4/14] /etc/doas.conf yapılandırması yapılıyor..."
echo 'permit setenv {PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin} :wheel' >> /etc/doas.conf
echo 'permit setenv { XAUTHORITY LANG LC_ALL } :wheel' >> /etc/doas.conf

echo "🔒 [5/14] doas.conf dosya izinleri ayarlanıyor..."
chown -c root:root /etc/doas.conf
chmod -c 0400 /etc/doas.conf

echo "✅ [6/14] doas yapılandırması kontrol ediliyor..."
if doas -C /etc/doas.conf; then
    echo "✅ doas yapılandırması doğru (config ok)"
else
    echo "❌ doas yapılandırma hatası (config error)"
fi

read -p "⏸️ [7/14] Devam etmek için Enter'a bas..."

echo "🔁 [8/14] sudo yerine doas sembolik linki oluşturuluyor..."
mv /usr/bin/sudo /usr/bin/sudobak
ln -s $(which doas) /usr/bin/sudo

echo "📦 [9/14] Derleme için gerekli paketler kuruluyor..."
apt install -y dkms git build-essential cmake libpci-dev linux-headers-$(uname -r)

echo "🎮 [10/14] NVIDIA sürücüleri kuruluyor..."
apt install -y nvidia-kernel-dkms nvidia-driver firmware-misc-nonfree

echo "⚙️ [11/14] ryzen_smu indiriliyor ve kuruluyor..."
git clone https://github.com/amkillam/ryzen_smu.git
cd ryzen_smu || { echo "❌ ryzen_smu klasörü bulunamadı"; exit 1; }
make dkms-install
cd ..
echo -e "# Load ryzen_smu driver upon startup\nryzen_smu" > /etc/modules-load.d/ryzen_smu.conf

echo "⚙️ [12/14] RyzenAdj indiriliyor ve derleniyor..."
git clone https://github.com/FlyGoat/RyzenAdj
cd RyzenAdj || { echo "❌ RyzenAdj klasörü bulunamadı"; exit 1; }
cmake -B build -DCMAKE_BUILD_TYPE=Release
make -C build -j"$(nproc)"
cp -v build/ryzenadj /usr/local/bin/
cd ..

echo "⚙️ [13/14] MangoHud indiriliyor ve kuruluyor..."
git clone --recurse-submodules https://github.com/flightlessmango/MangoHud.git
cd MangoHud || { echo "❌ MangoHud klasörü bulunamadı"; exit 1; }
./build.sh build
./build.sh install
cd ..

echo "⚙️ [14/14] RyzenAdj systemd servisi oluşturuluyor ve etkinleştiriliyor..."

cat <<EOF > /etc/systemd/system/ryzenadj.service
[Unit]
Description=Set Ryzen power limits using RyzenAdj
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ryzenadj --stapm-limit=25000 --fast-limit=25000 --slow-limit=25000 --tctl-temp=70
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# Servisi etkinleştir
systemctl enable ryzenadj.service

echo "✅ Tüm işlemler başarıyla tamamlandı. Yeniden başlatma yapılmayacak."
