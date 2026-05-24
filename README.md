# 🎬 Biletle - Mobil Sinema ve Tiyatro Bilet Satış ve Rezervasyon Sistemi

## 📱 Uygulama Ekran Görüntüleri

<p align="center">
  <img src="image_748b06.png" width="30%" alt="Ana Ekran" />
  <img src="image_748747.png" width="30%" alt="Detay Ekranı" />
</p>

---

**Biletle**, kullanıcıların mobil cihazları üzerinden güncel sinema ve tiyatro etkinliklerini keşfedebileceği, seans ve salon bilgilerini görüntüleyebileceği, dinamik koltuk seçimi yaparak bilet rezervasyonu gerçekleştirebileceği ve PNR kodlu dijital biletler (QR kod) oluşturabileceği kapsamlı bir mobil programlama dönem projesidir.

Proje, modern yazılım mühendisliği prensiplerine uygun olarak **Katmanlı Mimari** ve **MVVM** desenleri kullanılarak geliştirilmiş, ön yüzde **Flutter (Dart)**, arka yüzde ise **Flask (Python)** ve **PostgreSQL** bulut veritabanı mimarisi entegre edilmiştir.

---

## 🚀 Öne Çıkan Teknik Özellikler & İş Mantığı

* **Katmanlı ve MVVM Mimari:** İş mantığı (Business Logic) ile arayüz katmanı (UI) tamamen birbirinden soyutlanmıştır. Durum yönetimi için endüstri standardı olan **Provider** deseni kullanılmıştır.
* **Token Tabanlı Oturum Yönetimi (JWT Auth):** Kullanıcı giriş süreçlerinde `Flask-JWT-Extended` kullanılarak güvenli access token'lar üretilir. Flutter tarafında bu token'lar `shared_preferences` ile cihaz hafızasında kalıcı tutulur ve `Dio Interceptor` mimarisiyle HTTP isteklerine otomatik enjekte edilir.
* **10 Dakikalık Geçici Koltuk Kilitleme Algoritması:** İki kullanıcının aynı anda aynı koltuğu seçmesini (Race Condition) engellemek amacıyla backend ve veritabanı seviyesinde zaman aşımı (TTL) mekanizması kurulmuştur. Satın alma aşamasındaki koltuklar 10 dakika rezerve tutulur, ödeme tamamlanmazsa otomatik olarak havuza geri bırakılır.
* **Dinamik QR Kod Üretimi:** Başarıyla tamamlanan her bilet rezervasyonu için benzersiz bir PNR kodu üretilir ve `qr_flutter` kütüphanesiyle gişe kontrollerine uygun taranabilir dinamik QR kodlara dönüştürülür.
* **Çoklu Platform ve Fragman Entegrasyonu:** Etkinlik detay sayfalarında `kIsWeb` kontrolü yapılarak Chrome (Web) üzerinde fragmanlar şık bir `IFrame Pop-up` katmanında açılırken, mobil tarafta yerel tarayıcıyı (`url_launcher`) tetikleyecek hibrit bir yapı kurgulanmıştır.
* **Gelişmiş Ağ ve Hata Yönetimi:** Standart HTTP kütüphaneleri yerine `Dio` tercih edilerek merkezi `ApiClient` oluşturulmuş; bağlantı zaman aşımları ve sunucudan dönen `HTTP 409 Conflict` (Koltuk Çakışması) gibi durumlar kullanıcı deneyimini bozmadan global hata yakalama bloklarıyla yönetilmiştir.

---

## 📁 Proje Klasör Yapısı

Proje, tek bir çatı altında mobil ön yüz ve backend servislerini barındıran monorepo düzenine sahiptir:

```text
├── mobile/                      # Flutter Mobil & Web Projesi
│   ├── lib/
│   │   ├── core/                # Ağ istemcisi (Dio), sabitler ve temalar
│   │   ├── data/                # Veri modelleri (SessionModel, MovieModel vb.) ve servisler
│   │   ├── providers/           # MVVM ViewModel katmanı (Auth, Reservation, Movie Providers)
│   │   └── screens/             # UI / Ekran Tasarımları (Home, EventDetail, MyTickets vb.)
│   └── pubspec.yaml             # Flutter paket yönetim ve bağımlılık dosyası
│
└── backend/                     # Python Flask REST API Sunucusu
    ├── routes/                  # API Uç Noktaları (Blueprint: auth.py, reservations.py)
    ├── models.py                # SQLAlchemy ORM Veritabanı Modelleri (User, Movie, Session)
    ├── app.py                   # Uygulama ana giriş noktası ve initialization
    ├── requirements.txt         # Python bağımlılık listesi (Flask, SQLAlchemy, JWT)
    └── .env.example             # Çevre değişkenleri şablonu (Database URL, JWT Secret Key)
```
🛠️ Kullanılan Teknolojiler ve Bağımlılıklar
Mobil Ön Yüz (Flutter / Dart)
provider (^6.1.5+1): Reaktif durum yönetimi (State Management).

dio (^5.9.2): Interceptor ve gelişmiş hata yönetimli HTTP istemcisi.

shared_preferences (^2.5.5): JWT token ve yerel kullanıcı ayarları kalıcılığı.

qr_flutter (^4.1.0): Dijital biletler için dinamik QR kod render motoru.

Youtubeer_iframe (^5.2.2) & url_launcher (^6.3.2): Web/Mobil uyumlu video oynatıcı altyapısı.

fl_chart (^1.2.0), sqflite, workmanager, connectivity_plus: Projenin ileri faz mimari hazırlıkları ve analitik grafikleri için entegre edilen paketler.

Arka Yüz (Python / Flask)
Flask (3.0.2): Hafif, modüler ve mikro REST API çatısı.

Flask-SQLAlchemy (3.1.1): PostgreSQL nesne-ilişkisel eşleme (ORM) katmanı.

Flask-JWT-Extended (4.6.0): Güvenli dijital imzalama ve token doğrulama mekanizması.

psycopg2-binary: PostgreSQL yüksek performanslı veritabanı sürücüsü.

⚙️ Kurulum ve Başlatma
1. Arka Yüzün Başlatılması (Backend)
Sanal ortamı (virtual environment) oluşturun, aktif edin ve gerekli Python paketlerini yükleyin:
```
cd backend
python -m venv venv
source venv/Scripts/activate  # Windows için: venv\Scripts\activate
pip install -r requirements.txt
```
backend klasörünün içerisinde bir .env dosyası oluşturup veritabanı bağlantı adresinizi ve JWT gizli anahtarınızı tanımlayın:
DATABASE_URL=postgresql://kullanici:sifre@localhost:5432/bilet_db
JWT_SECRET_KEY=super_gizli_anahtar_prensibi

Backend REST API sunucusunu başlatın:
```
python app.py
```
2. Ön Yüzün Başlatılması (Mobile)
Gerekli Flutter paketlerini çekin ve uygulamayı yerelinizde ayağa kaldırın:
```
cd mobile
flutter pub get
flutter run
```
