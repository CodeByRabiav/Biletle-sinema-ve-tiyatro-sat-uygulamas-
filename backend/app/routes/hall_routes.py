from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app.extensions import db
from app.models.hall import Hall
from app.models.seat import Seat
from app.models.session import Session
from app.utils.auth_helpers import is_admin
from math import radians, cos, sin, asin, sqrt

hall_bp = Blueprint("halls", __name__, url_prefix="/halls")

# --- OKUMA (GET) İŞLEMLERİ ---

@hall_bp.route("", methods=["GET"])
def get_halls():
    """Tüm salonları listeler"""
    halls = Hall.query.order_by(Hall.id.desc()).all()
    return jsonify([hall.to_dict() for hall in halls]), 200

@hall_bp.route("/cities", methods=["GET"])
def get_cities():
    """Biletinial tarzı: Sadece mevcut şehirlerin listesini döner"""
    cities = db.session.query(Hall.city).distinct().all()
    return jsonify([city[0] for city in cities]), 200

@hall_bp.route("/filter", methods=["GET"])
def filter_halls():
    """Şehir ve türüne göre mekanları filtreler"""
    venue_type = request.args.get("venue_type", "").strip().lower()
    city = request.args.get("city", "").strip()
    district = request.args.get("district", "").strip()

    query = Hall.query

    if venue_type:
        query = query.filter(Hall.venue_type == venue_type)
    if city:
        query = query.filter(Hall.city.ilike(city))
    if district:
        query = query.filter(Hall.district.ilike(district))

    halls = query.order_by(Hall.name.asc()).all()
    return jsonify([hall.to_dict() for hall in halls]), 200

@hall_bp.route("/<int:hall_id>", methods=["GET"])
def get_hall(hall_id):
    """Tek bir salonun detayını ve koltuklarını döner"""
    hall = Hall.query.get(hall_id)
    if not hall:
        return jsonify({"error": "Salon bulunamadı"}), 404

    hall_data = hall.to_dict()
    hall_data["seats"] = [seat.to_dict() for seat in hall.seats]
    return jsonify(hall_data), 200

@hall_bp.route("/<int:hall_id>/sessions", methods=["GET"])
def get_hall_sessions(hall_id):
    """Biletinial tarzı: Seçilen salonda hangi filmler/seanslar var?"""
    hall = Hall.query.get_or_404(hall_id)
    sessions = Session.query.filter_by(hall_id=hall_id).all()
    
    return jsonify({
        "hall_id": hall.id,
        "hall_name": hall.name,
        "sessions": [session.to_dict() for session in sessions]
    }), 200

# --- KONUM TABANLI (GEO) İŞLEMLER ---

def haversine(lat1, lon1, lat2, lon2):
    R = 6371  # km
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat / 2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2)**2
    c = 2 * asin(sqrt(a))
    return R * c

@hall_bp.route("/nearby", methods=["GET"])
def get_nearby_halls():
    """Yakındaki salonları mesafe hesaplayarak döner"""
    try:
        user_lat = float(request.args.get("lat"))
        user_lon = float(request.args.get("lon"))
    except:
        return jsonify({"error": "lat ve lon gerekli"}), 400

    radius = float(request.args.get("radius", 5))  # varsayılan 5km
    venue_type = request.args.get("venue_type")

    halls = Hall.query.all()
    result = []

    for hall in halls:
        if venue_type and hall.venue_type != venue_type:
            continue
        
        distance = haversine(user_lat, user_lon, hall.latitude, hall.longitude)
        if distance <= radius:
            result.append({
                "id": hall.id,
                "name": hall.name,
                "city": hall.city,
                "district": hall.district,
                "venue_type": hall.venue_type,
                "distance_km": round(distance, 2)
            })

    result.sort(key=lambda x: x["distance_km"])
    return jsonify(result), 200

# --- YAZMA (POST) İŞLEMLERİ ---

@hall_bp.route("", methods=["POST"])
@jwt_required()
def create_hall():
    """Yeni salon ve koltuk şablonu oluşturur (Admin)"""
    if not is_admin():
        return jsonify({"error": "Bu işlem için admin yetkisi gerekir"}), 403

    data = request.get_json()
    if not data:
        return jsonify({"error": "JSON veri gönderilmedi"}), 400

    name = data.get("name", "").strip()
    city = data.get("city", "").strip()
    district = data.get("district", "").strip()
    venue_type = data.get("venue_type", "").strip().lower()
    row_count = data.get("row_count")
    column_count = data.get("column_count")
    lat = data.get("latitude", 0.0)
    lon = data.get("longitude", 0.0)

    if not all([name, city, district, venue_type, row_count, column_count]):
        return jsonify({"error": "Eksik alanlar var"}), 400

    if venue_type not in ["cinema", "theater"]:
        return jsonify({"error": "venue_type cinema veya theater olmalı"}), 400

    existing_hall = Hall.query.filter_by(name=name).first()
    if existing_hall:
        return jsonify({"error": "Bu salon adı zaten kayıtlı"}), 409

    hall = Hall(
        name=name,
        city=city,
        district=district,
        venue_type=venue_type,
        row_count=int(row_count),
        column_count=int(column_count),
        latitude=float(lat),
        longitude=float(lon)
    )

    db.session.add(hall)
    db.session.flush()

    # Otomatik koltuk oluşturma
    for row_index in range(hall.row_count):
        row_label = chr(65 + row_index)
        for seat_number in range(1, hall.column_count + 1):
            seat = Seat(
                hall_id=hall.id,
                row_label=row_label,
                seat_number=seat_number
            )
            db.session.add(seat)

    db.session.commit()
    return jsonify({"message": "Salon başarıyla oluşturuldu", "hall": hall.to_dict()}), 201