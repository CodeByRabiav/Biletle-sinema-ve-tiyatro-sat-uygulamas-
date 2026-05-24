from datetime import datetime
from app.extensions import db

class Movie(db.Model):
    __tablename__ = "movies"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(150), nullable=False)
    description = db.Column(db.Text, nullable=True)
    duration = db.Column(db.Integer, nullable=False)
    category = db.Column(db.String(100), nullable=False)
    image_url = db.Column(db.String(255), nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    content_type = db.Column(db.String(50), nullable=False, default="cinema")
    
    cast = db.Column(db.String(500), nullable=True)
    trailer_url = db.Column(db.String(255), nullable=True)
    
    sessions = db.relationship("Session", backref="movie", lazy=True, cascade="all, delete-orphan")
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "duration": self.duration,
            "category": self.category,
            "image_url": self.image_url,
            "is_active": self.is_active,
            "content_type": self.content_type, 
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "cast": self.cast, # getattr yerine artık doğrudan bunu yazabiliriz
            "trailer_url": self.trailer_url
        }