from datetime import datetime

from app.extensions import db


class Ticket(db.Model):
    __tablename__ = "tickets"

    id = db.Column(db.Integer, primary_key=True)
    reservation_id = db.Column(db.Integer, db.ForeignKey("reservations.id"), nullable=False, unique=True)
    ticket_code = db.Column(db.String(50), nullable=False, unique=True)
    qr_data = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "reservation_id": self.reservation_id,
            "ticket_code": self.ticket_code,
            "qr_data": self.qr_data,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }