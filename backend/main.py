from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from supabase import create_client, Client
from dotenv import load_dotenv
import os
from pathlib import Path # Bunu ekle

# --- GÜNCELLEME BAŞLANGICI ---

# .env dosyasının yolunu açıkça belirtiyoruz
env_path = Path('.') / '.env'
load_dotenv(dotenv_path=env_path)

URL = os.getenv("SUPABASE_URL")
KEY = os.getenv("SUPABASE_KEY")

# Hata Ayıklama: Eğer okuyamazsa konsola hata bassın
if not URL or not KEY:
    print(" HATA: .env dosyası okunamadı! Lütfen dosya adını kontrol et.")
    print(f"Aranan dosya yolu: {env_path.absolute()}")
else:
    print(".env başarıyla okundu.")

# --- GÜNCELLEME BİTİŞİ ---

# Supabase Bağlantısı
try:
    supabase: Client = create_client(URL, KEY)
except Exception as e:
    print("Supabase bağlantı hatası:", e)

# FastAPI Uygulamasını Başlat
app = FastAPI()

# ... Kodun geri kalanı aynı ...

# 2. Veri Modelleri (Kullanıcıdan ne bekliyoruz?)
class SearchRequest(BaseModel):
    lat: float
    long: float
    radius: int = 2000 # Varsayılan 2 km
    type: str = "all"  # 'bar', 'pub' veya hepsi

class CreateRequest(BaseModel):
    user_id: str # Normalde Token'dan alınır ama şimdilik elden alalım
    group_size: int
    preferred_type: str
    lat: float
    long: float

# 3. Endpointler (API Uçları)

@app.get("/")
def read_root():
    return {"Durum": "Backend Ayakta! 🚀"}

# A. Yakındaki Mekanları Listeleme Endpoint'i
@app.post("/find-venues")
def find_venues(request: SearchRequest):
    try:
        # SQL tarafında yazdığımız fonksiyonu çağırıyoruz (RPC)
        response = supabase.rpc(
            "find_nearby_venues", 
            {
                "user_lat": request.lat,
                "user_long": request.long,
                "radius_meters": request.radius,
                "filter_type": request.type
            }
        ).execute()
        
        return {"data": response.data}
    
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# B. Yeni Talep Oluşturma Endpoint'i
@app.post("/create-request")
def create_request(req: CreateRequest):
    try:
        # 1. Talebi veritabanına kaydet
        # Not: PostGIS formatında veri eklemek için raw SQL'e yakın bir format kullanıyoruz
        # veya Supabase client'ın 'insert' metodu ile coğrafi veriyi string olarak yolluyoruz.
        
        location_string = f"SRID=4326;POINT({req.long} {req.lat})"
        
        data = {
            "user_id": req.user_id,
            "group_size": req.group_size,
            "preferred_type": req.preferred_type,
            "user_location": location_string
        }
        
        response = supabase.table("requests").insert(data).execute()
        
        return {"message": "Talep oluşturuldu!", "details": response.data}
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))