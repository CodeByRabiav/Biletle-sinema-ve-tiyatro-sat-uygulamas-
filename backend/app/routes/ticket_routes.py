import uuid
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models.ticket import Ticket
from app.models.reservation import Reservation
from app.extensions import db

ticket_bp = Blueprint("tickets", __name__, url_prefix="/tickets")

# 1. Ödemeyi Onayla ve Bilet Oluştur
@ticket_bp.route("/purchase/<int:reservation_id>", methods=["POST"])
@jwt_required()
def purchase_ticket(reservation_id):
    res = Reservation.query.get(reservation_id)
    if not res:
        return jsonify({"error": "Rezervasyon bulunamadı"}), 404
    
    # 🔥 GÜVENLİK: Eğer bu rezervasyona zaten bilet kesilmişse işlemi durdur
    if res.ticket:
        return jsonify({"error": "Bu rezervasyon için zaten bilet alınmış"}), 400
    
    # Rezervasyonu 'paid' (ödendi) yap
    res.payment_status = "paid"
    
    # Benzersiz Bilet Kodu ve QR Verisi Üret
    t_code = str(uuid.uuid4())[:8].upper()
    new_ticket = Ticket(
        reservation_id=res.id,
        ticket_code=t_code,
        qr_data=f"VALID-{t_code}"
    )
    
    db.session.add(new_ticket)
    db.session.commit()
    
    # 🔥 FLUTTER UYUMU: ticket_code bilgisini de Flutter'a gönderiyoruz
    return jsonify({
        "message": "Bilet oluşturuldu", 
        "ticket_id": new_ticket.id,
        "ticket_code": new_ticket.ticket_code 
    }), 201

# 2. Biletlerimi Listele
@ticket_bp.route("/my", methods=["GET"])
@jwt_required()
def get_my_tickets():
    current_user_id = int(get_jwt_identity())
    reservations = Reservation.query.filter_by(user_id=current_user_id, payment_status="paid").all()
    
    tickets = []
    for res in reservations:
        if res.ticket:
            tickets.append(res.ticket.to_dict())
            
    return jsonify(tickets), 200