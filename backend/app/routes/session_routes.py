from datetime import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required

from app.extensions import db
from app.models.movie import Movie
from app.models.hall import Hall
from app.models.session import Session
from app.utils.auth_helpers import is_admin

session_bp = Blueprint("sessions", __name__, url_prefix="/sessions")

# 1. Tüm Seansları Getir
@session_bp.route("", methods=["GET"])
def get_sessions():
    sessions = Session.query.order_by(Session.start_time.asc()).all()
    # session.to_dict() artık güncellediğimiz session.py içindeki gelişmiş to_dict()'i kullanacak
    return jsonify([session.to_dict() for session in sessions]), 200

# 2. Belirli Bir Filme Ait Seansları Getir (Flutter Detay -> Seans akışı için kritik)
@session_bp.route("/movie/<int:movie_id>", methods=["GET"])
def get_sessions_by_movie(movie_id):
    sessions = Session.query.filter_by(movie_id=movie_id).order_by(Session.start_time.asc()).all()
    
    if not sessions:
        # Boş liste dönmesi Flutter'da hata vermez, "seans yok" mesajı gösterir
        return jsonify([]), 200
        
    return jsonify([session.to_dict() for session in sessions]), 200

# 3. Belirli Bir Salona Ait Seansları Getir
@session_bp.route("/hall/<int:hall_id>", methods=["GET"])
def get_sessions_by_hall(hall_id):
    sessions = Session.query.filter_by(hall_id=hall_id).order_by(Session.start_time.asc()).all()
    return jsonify([session.to_dict() for session in sessions]), 200

# 4. Yeni Seans Oluştur (Admin)
@session_bp.route("", methods=["POST"])
@jwt_required()
def create_session():
    if not is_admin():
        return jsonify({"error": "Bu işlem için admin yetkisi gerekir"}), 403

    data = request.get_json()
    if not data:
        return jsonify({"error": "JSON veri gönderilmedi"}), 400

    movie_id = data.get("movie_id")
    hall_id = data.get("hall_id")
    start_time_str = data.get("start_time")
    price = data.get("price")

    if not all([movie_id, hall_id, start_time_str, price is not None]):
        return jsonify({"error": "movie_id, hall_id, start_time ve price zorunludur"}), 400

    # Movie ve Hall kontrolü
    movie = Movie.query.get(movie_id)
    hall = Hall.query.get(hall_id)
    
    if not movie:
        return jsonify({"error": "İçerik (Film/Tiyatro) bulunamadı"}), 404
    if not hall:
        return jsonify({"error": "Salon bulunamadı"}), 404

    # Tarih parse işlemi
    try:
        start_time = datetime.fromisoformat(start_time_str)
    except ValueError:
        return jsonify({"error": "Geçersiz tarih formatı. ISO formatı kullanın (YYYY-MM-DDTHH:MM:SS)"}), 400

    # Yeni seans kaydı
    new_session = Session(
        movie_id=movie_id,
        hall_id=hall_id,
        start_time=start_time,
        price=float(price)
    )

    db.session.add(new_session)
    db.session.commit()

    return jsonify({
        "message": "Seans başarıyla oluşturuldu",
        "session": new_session.to_dict()
    }), 201