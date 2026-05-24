from datetime import datetime
from app.extensions import db

class Session(db.Model):
    __tablename__ = "sessions"

    id = db.Column(db.Integer, primary_key=True)
    movie_id = db.Column(db.Integer, db.ForeignKey("movies.id"), nullable=False)
    hall_id = db.Column(db.Integer, db.ForeignKey("halls.id"), nullable=False)
    start_time = db.Column(db.DateTime, nullable=False)
    price = db.Column(db.Float, nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # DİKKAT: Burada elinle 'movie =' veya 'hall =' tanımlama! 
    # Onlar diğer dosyalardaki backref'lerden gelecek.

    def to_dict(self):
        # Movie ve Hall objelerine backref üzerinden ulaşıyoruz.
        return {
            "id": self.id,
            "movie_id": self.movie_id,
            "hall_id": self.hall_id,
            "hall_name": self.hall.name if self.hall else "Bilinmeyen Salon",
            "movie_title": self.movie.title if self.movie else "Bilinmeyen Film",
            "image_url": getattr(self.movie, 'image_url', ''),
            "movie_cast": getattr(self.movie, 'cast', ''),
            "start_time": self.start_time.isoformat() if self.start_time else None,
            "time": self.start_time.strftime("%H:%M") if self.start_time else "00:00",
            "price": self.price
        }