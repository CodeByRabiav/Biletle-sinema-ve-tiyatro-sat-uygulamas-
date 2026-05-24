from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.movie import Movie
from flask_jwt_extended import jwt_required
from app.utils.auth_helpers import is_admin

movie_bp = Blueprint("movies", __name__, url_prefix="/movies")

# 1. Tüm Filmleri/Tiyatroları Getir (contentType'a göre filtreleme destekli)
@movie_bp.route("", methods=["GET"])
def get_movies():
    content_type = request.args.get("content_type", "").strip().lower()
    
    query = Movie.query
    if content_type:
        query = query.filter_by(content_type=content_type)
    
    movies = query.all()
    return jsonify([movie.to_dict() for movie in movies]), 200

# 2. Tek Bir Film Detayını Getir (Flutter'ın hata aldığı yer burası olabilir)
@movie_bp.route("/<int:movie_id>", methods=["GET"])
def get_movie(movie_id):
    # .get() yerine .get_or_404() de kullanılabilir ama hata mesajını biz yönetelim
    movie = Movie.query.get(movie_id)
    
    if not movie:
        print(f"Hata: {movie_id} ID'li film veritabanında yok!") # Debug için log ekledik
        return jsonify({"error": "İçerik bulunamadı", "received_id": movie_id}), 404
        
    return jsonify(movie.to_dict()), 200

# 3. Yeni İçerik Ekle (Admin)
@movie_bp.route("", methods=["POST"])
@jwt_required()
def create_movie():
    if not is_admin():
        return jsonify({"error": "Admin yetkisi gerekiyor"}), 403
        
    data = request.get_json()
    if not data or 'title' not in data:
        return jsonify({"error": "Eksik veri"}), 400

    new_movie = Movie(
        title=data.get('title'),
        description=data.get('description'),
        duration=data.get('duration', 90),
        category=data.get('category'),
        image_url=data.get('image_url'),
        content_type=data.get('content_type', 'cinema')
    )
    
    db.session.add(new_movie)
    db.session.commit()
    return jsonify(new_movie.to_dict()), 201