# Debian 13 Victus 16 S1002-NT
---

## ✨ Özellikler

* 🔒 **Sudo Alternatifi:** Doas kurulumu ve yapılandırması.
* ⚙️ **Nvidia Sürücüleri:** Kapalı kaynak Nvidia Sürücülerinin kurulumu(550.163.01).
* 🌡️ **İşlemciye Güç ve Sıcaklık Limiti:** AMD Ryzen 7 8845HS işlemciye 28W ve 70°C limit koyma işlemi.
* 🎮 **Oyun araçlarının kurulumu:** Steam, Gamemode, Mangohud vb. paketlerin kurulumu. 
---

## 🛠️ Kurulum

⚠️BU REHBERİN DEBİAN 13 TEMEL SİSTEMİ VE MASAÜSTÜ ORTAMI KURULDUKTAN SONRA UYGULANMASI DAHA UYGUN OLACAKTIR!⚠️
**Ön Gereksinimler:**
* Kurulumu tamamlanmış ve masaüstü ortamına ulaşılmış Debian 13 kurulumu

**Adımlar:**
    # APT yapılandırması
1.  Repoyu klonlayın:
    ```sh
    git clone [https://github.com/kullanici-adiniz/proje-adiniz.git](https://github.com/kullanici-adiniz/proje-adiniz.git)
    ```
2.  Proje dizinine gidin:
    ```sh
    cd proje-adiniz
    ```
3.  Gerekli paketleri yükleyin:
    ```sh
    npm install
    ```
4.  Uygulamayı başlatın:
    ```sh
    npm start
    ```

---

## 🚀 Kullanım

Projenizin nasıl kullanılacağına dair örnekler verin. Mümkünse kod blokları ve ekran görüntüleri ile destekleyin.

**Örnek Kod:**
```javascript
const proje = require('proje-adi');

const sonuc = proje.harikaFonksiyon(5, 10);
console.log(sonuc); // Çıktı: 15
