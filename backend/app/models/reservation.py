from datetime import datetime
from app.extensions import db

class Reservation(db.Model):
    __tablename__ = "reservations"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    session_id = db.Column(db.Integer, db.ForeignKey("sessions.id"), nullable=False)
    status = db.Column(db.String(20), nullable=False, default="pending") # 'pending' = kilitli/beklemede, 'completed' = satıldı
    total_price = db.Column(db.Float, nullable=False, default=0)
    payment_status = db.Column(db.String(20), nullable=False, default="unpaid")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    #   Geçici Kilitleme Süresi
    locked_at = db.Column(db.DateTime, default=datetime.utcnow)

    ticket = db.relationship("Ticket", backref="reservation", uselist=False, cascade="all, delete-orphan")
    reserved_seats = db.relationship("ReservationSeat", backref="reservation", lazy=True, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "session_id": self.session_id,
            "status": self.status,
            "total_price": self.total_price,
            "payment_status": self.payment_status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "locked_at": self.locked_at.isoformat() if self.locked_at else None, # JSON'a eklendi
        }


class ReservationSeat(db.Model):
    __tablename__ = "reservation_seats"

    id = db.Column(db.Integer, primary_key=True)
    reservation_id = db.Column(db.Integer, db.ForeignKey("reservations.id"), nullable=False)
    seat_id = db.Column(db.Integer, db.ForeignKey("seats.id"), nullable=False)

    seat = db.relationship("Seat")

    def to_dict(self):
        return {
            "id": self.id,
            "reservation_id": self.reservation_id,
            "seat_id": self.seat_id,
            "seat": self.seat.to_dict() if self.seat else None,
        }