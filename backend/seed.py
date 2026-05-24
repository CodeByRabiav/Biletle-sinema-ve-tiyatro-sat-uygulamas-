import os
from datetime import datetime, timedelta
from app import create_app
from app.extensions import db
from app.models.hall import Hall
from app.models.movie import Movie
from app.models.session import Session
from app.models.seat import Seat

app = create_app()

def run_seed():
    with app.app_context():
        print("🧹 Eski veriler temizleniyor...")
        db.drop_all()
        db.create_all()

        # --- 1. FİLMLERİ VE OYUNLARI EKLE ---
        print("🎬 İçerikler ekleniyor...")
        m1 = Movie(
            title="Dune: Part Two", 
            duration=166, 
            category="Aksiyon/Bilim Kurgu", 
            content_type="cinema", 
            description="Paul Atreides'in yükselişini konu alan epik hikaye.",
            image_url="https://m.media-amazon.com/images/M/MV5BN2QyZGU4ZDctOWMzMy00NTc5LThlOGQtODhmNDI1NmY5YzAwXkEyXkFqcGdeQXVyMDM2NDM2MQ@@.V1.jpg"
        )
        m2 = Movie(
            title="Zengin Mutfağı", 
            duration=140, 
            category="Dram/Komedi", 
            content_type="theater", 
            description="Şener Şen'in başrolünde olduğu efsane tiyatro oyunu.",
            image_url="https://tiyatrolar.com.tr/system/shows/logos/000/004/187/original/zengin-mutfagi.jpg"
        )
        db.session.add_all([m1, m2])
        db.session.commit() # ID'lerin oluşması için commit şart

        # --- 2. SALONLARI EKLE ---
        print("🏛️ Salonlar ekleniyor...")
        h1 = Hall(
            name="Paribu Cineverse (Zorlu)", 
            city="İstanbul", 
            district="Beşiktaş", 
            venue_type="cinema", 
            row_count=5, 
            column_count=8, 
            latitude=41.066, 
            longitude=29.017
        )
        h2 = Hall(
            name="Kadıköy Halk Eğitim", 
            city="İstanbul", 
            district="Kadıköy", 
            venue_type="theater", 
            row_count=6, 
            column_count=10, 
            latitude=40.989, 
            longitude=29.027
        )
        db.session.add_all([h1, h2])
        db.session.commit()

        # --- 3. KOLTUKLARI OLUŞTUR ---
        print("💺 Koltuklar oluşturuluyor...")
        for hall in [h1, h2]:
            for r in range(hall.row_count):
                row_label = chr(65 + r) # A, B, C...
                for c in range(1, hall.column_count + 1):
                    seat = Seat(hall_id=hall.id, row_label=row_label, seat_number=c)
                    db.session.add(seat)
        db.session.commit()

        # --- 4. SEANSLARI EKLE (EN KRİTİK ADIM) ---
        print("🗓️ Seanslar planlanıyor...")
        # Yarın saat 20:00'ye bir seans
        s1_time = datetime.now().replace(hour=20, minute=0, second=0, microsecond=0) + timedelta(days=1)
        
        # Dune Seansı (Sinema)
        s1 = Session(
            movie_id=m1.id, 
            hall_id=h1.id, 
            start_time=s1_time, 
            price=150.0
        )
        
        # Zengin Mutfağı Seansı (Tiyatro)
        s2 = Session(
            movie_id=m2.id, 
            hall_id=h2.id, 
            start_time=s1_time + timedelta(hours=1), # 21:00
            price=250.0
        )

        db.session.add_all([s1, s2])
        db.session.commit()

        print("🚀 İŞLEM TAMAM: Veritabanı başarıyla dolduruldu!")
        print(f"Dune ID: {m1.id} | Seans ID: {s1.id}")

if __name__ == "__main__":
    run_seed()