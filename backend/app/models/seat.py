from app.extensions import db


class Seat(db.Model):
    __tablename__ = "seats"

    id = db.Column(db.Integer, primary_key=True)
    hall_id = db.Column(db.Integer, db.ForeignKey("halls.id"), nullable=False)
    row_label = db.Column(db.String(5), nullable=False)
    seat_number = db.Column(db.Integer, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "hall_id": self.hall_id,
            "row_label": self.row_label,
            "seat_number": self.seat_number,
        }