
# Debian 13 Victus 16 S1002-NT
---

## ✨ Özellikler

 - 🌐 **Apt Yapılandırması:** Paket yöneticisinde kapalı kaynak ve 32-bit paket listesinin aktif edilmesi.
 - 🔒 **Sudo Alternatifi:** Doas kurulumu ve yapılandırması.
 - ⚙️ **Nvidia Sürücüleri:** Kapalı kaynak Nvidia Sürücülerinin kurulumu(550.163.01).
 - 🌡️ **İşlemciye Güç ve Sıcaklık Limiti:** AMD Ryzen 7 8845HS işlemciye 28W ve 70°C limit koyma işlemi.
 - 🎮 **Oyun araçlarının kurulumu:** Steam, Gamemode, Mangohud vb. paketlerin kurulumu. 
---

## 🛠️ Kurulum

⚠️BU REHBERİN DEBİAN 13 TEMEL SİSTEMİ VE MASAÜSTÜ ORTAMI KURULDUKTAN SONRA UYGULANMASI DAHA UYGUN OLACAKTIR!⚠️
**Ön Gereksinimler:**
* Kurulumu tamamlanmış ve masaüstü ortamına ulaşılmış Debian 13 kurulumu
* Sudo veya Root kullanıcısı (Eğer adım numaralandırmasının başında 🔑 işareti varsa bu komutun root izinleri ile çalıştırılması gerektiğini gösterir.)

### 🌐 Apt Yapılandırması:
1.  🔑"contrib", "non-free" ve "non-free-firmware" bileşenlerini /etc/apt/sources.list dosyasına ekleyin:
    ```sh
    sed -i 's|^deb http://deb.debian.org/debian/ trixie main non-free-firmware\$|deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware|' /etc/apt/sources.list
    sed -i 's|^deb http://security.debian.org/debian-security trixie-security main  non-free-firmware\$|deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware|' /etc/apt/sources.list
    ```
2.  🔑32-bit paketleri etkinleştirin:
    ```sh
    dpkg --add-architecture i386
    ```
3.  🔑Paket listesini güncelleyin ve varsa paketleri güncelleyin:
    ```sh
    apt update && apt upgrade
    ```
### 🔒Doas Kurulumu ve Yapılandırması:
1. 🔑Doas paketinin kurun:
	```sh
	apt install doas
	```
2. 🔑/etc/doas.conf dosyasını yapılandırın:
	```sh
	echo \permit setenv {PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin} \"KULLANICI_ADI"\ >> /etc/doas.conf
	echo \permit setenv { XAUTHORITY LANG LC_ALL } \"KULLANICI_ADI"\ >> /etc/doas.conf
	```
	> !!! "KULLANICI_ADI" kısmında kendi kullanıcı adınızı Tırnak (") işareti OLMADAN yazın !!!
	
  3. 🔑Yapılandırma dosyasının izinlerini ayarlayın:
		```sh
		chmod 0400 /etc/doas.conf && chown root:root /etc/doas.conf
		``` 
4. 🔑Sudo komutunu Doas ile değiştirin:
	```sh
	mv /usr/bin/sudo /usr/bin/sudobak
	ln -s \$(which doas) /usr/bin/sudo
	```

### ⚙️ Nvidia Sürücülerinin Kurulumu:

1.  🔑Kapalı kaynak Nvidia sürücülerini kurun:
    ```sh
    apt install apt install nvidia-driver-libs:i386 nvidia-kernel-dkms nvidia-driver firmware-misc-nonfree
    ```
### 🌡️İşlemciye Güç ve Sıcaklık Limiti:

2. RYZEN_SMU modülünü kurun:
	```sh
	sudo apt install dkms git build-essential linux-headers-$(uname -r)
	git clone https://github.com/amkillam/ryzen_smu.git
	cd ryzen_smu
	sudo make dkms-install
	echo -e '# Load ryzen_smu driver upon startup\nryzen_smu' | doas tee /etc/modules-load.d/		ryzen_smu.conf
	```
3. RyzenAdj paketini kurun:
	```sh
	sudo apt install build-essential cmake libpci-dev
	git clone https://github.com/FlyGoat/RyzenAdj.git
	cd RyzenAdj
	cmake -B build -DCMAKE_BUILD_TYPE=Release
	make -C build -j$(nproc)
	sudo cp build/ryzenadj /usr/local/bin/
	```
	3a. RyzenAdj servisi oluşturun:
	* 🔑/etc/systemd/system/ryzenadj.service dosyası oluşturun ve içerisine aşağıdaki satırları yazıp kaydedin:
	```sh
	[Unit]
	Description=Set Ryzen power limits using RyzenAdj
	After=multi-user.target
 
	[Service]
	Type=oneshot
	ExecStart=/usr/local/bin/ryzenadj --stapm-limit=25000 --fast-limit=25000 --slow-limit=25000 --tctl-temp=70
	RemainAfterExit=true
 
	[Install]
	WantedBy=multi-user.target
	```
	*🔑RyzenAdj servisini etkinleştirin:
	```sh
	systemctl enable ryzenadj.service
	```
### 🎮 Oyun araçlarının kurulumu:
1. 🔑Steam kurun:
 > Steam paketi "steam-installer" paketinin çalıştırılması ile kurulacaktır.
```sh
apt install steam-installer
```
2. Mangohud kurun:
```sh
git clone --recurse-submodules https://github.com/flightlessmango/MangoHud.git
cd MangoHud
./build.sh build
./build.sh install
```
3.  🔑Gamemode kurun:
```sh
apt install gamemode
```



