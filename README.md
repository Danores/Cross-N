# Cross-N

Bu proje, iki farklı mobil uygulama arasında anlık bir bildirim ve onay/ret döngüsü kurmayı sağlayan tam yığın (full-stack) bir sistemdir. Backend tarafında yüksek performanslı bir API sunmak için **FastAPI**, veritabanı yönetimi için **Supabase**, mobil arayüzler için ise **Flutter/Dart** kullanılmıştır.

##  Kurulum ve Çalıştırma

### 1. Backend Kurulumu (FastAPI)
Projeyi çalıştırmadan önce `backend` klasöründe kendi `.env` dosyanızı oluşturup Supabase bilgilerinizi (URL ve KEY) girmeniz gerekmektedir.

### Sanal ortamı aktif edip kütüphaneleri kurun ve sunucuyu başlatın:

cd backend
python -m venv venv
Windows: venv\Scripts\activate | Mac/Linux: source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload

### Ayrı terminallerde flutter dosyalarını aktif etme
cd frontend/venue_app
flutter run

cd frontend/customer_app
flutter run
