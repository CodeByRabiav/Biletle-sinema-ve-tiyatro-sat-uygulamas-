from app import create_app
from flask_cors import CORS  # 1. YENİ EKLENEN SATIR

app = create_app()

# 2. YENİ EKLENEN SATIR: Tüm dış bağlantılara (Özellikle Chrome'daki Flutter'a) izin ver
CORS(app) 

if __name__ == "__main__":
    app.run(debug=True)