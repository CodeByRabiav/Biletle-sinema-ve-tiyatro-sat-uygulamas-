from datetime import datetime
from app.extensions import db

class Hall(db.Model):
    __tablename__ = "halls"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False, unique=True)
    city = db.Column(db.String(100), nullable=False)
    district = db.Column(db.String(100), nullable=False)
    venue_type = db.Column(db.String(20), nullable=False)  # cinema / theater
    row_count = db.Column(db.Integer, nullable=False)
    column_count = db.Column(db.Integer, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Konum bilgileri
    latitude = db.Column(db.Float, nullable=False)
    longitude = db.Column(db.Float, nullable=False)

    seats = db.relationship("Seat", backref="hall", lazy=True, cascade="all, delete-orphan")
    sessions = db.relationship("Session", backref="hall", lazy=True, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "city": self.city,
            "district": self.district,
            "venue_type": self.venue_type,
            "row_count": self.row_count,
            "column_count": self.column_count,
            "latitude": self.latitude,   # 🔥 FLUTTER İÇİN EKLENDİ
            "longitude": self.longitude, # 🔥 FLUTTER İÇİN EKLENDİ
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }