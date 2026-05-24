import json
import uuid
from datetime import datetime, timedelta

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from app.extensions import db
from app.models.session import Session
from app.models.seat import Seat
from app.models.reservation import Reservation, ReservationSeat
from app.models.ticket import Ticket

reservation_bp = Blueprint("reservations", __name__, url_prefix="/reservations")


@reservation_bp.route("/session/<int:session_id>/occupied-seats", methods=["GET"])
def get_occupied_seats(session_id):
    session = Session.query.get(session_id)
    if not session:
        return jsonify({"error": "Seans bulunamadı"}), 404

    # GÜNCELLEME: Sadece SATILANLARI değil, hala "Beklemede/Kilitli" olanları da DOLU göster
    # Tembel Temizlik (Lazy Cleanup) - Önce süresi dolanları silelim ki boş yere dolu gözükmesin
    expire_time = datetime.utcnow() - timedelta(minutes=10)
    expired_reservations = Reservation.query.filter(
        Reservation.session_id == session_id,
        Reservation.status == "pending",
        Reservation.locked_at < expire_time
    ).all()
    
    for exp_res in expired_reservations:
        db.session.delete(exp_res)
    db.session.commit()

    # Şimdi geçerli olan satılmış (completed) veya hala kilitli (pending) olanları çekiyoruz
    reservations = Reservation.query.filter(
        Reservation.session_id == session_id,
        Reservation.status.in_(["completed", "pending"]) 
    ).all()

    occupied = []
    for reservation in reservations:
        for rs in reservation.reserved_seats:
            if rs.seat:
                occupied.append({
                    "seat_id": rs.seat.id,
                    "row_label": rs.seat.row_label,
                    "seat_number": rs.seat.seat_number,
                    "status": reservation.status # Flutter tarafında gri mi yoksa kırmızı mı çizeceğini bilmek için
                })

    return jsonify(occupied), 200


@reservation_bp.route("", methods=["POST"])
@jwt_required()
def create_reservation():
    current_user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data:
        return jsonify({"error": "JSON veri gönderilmedi"}), 400

    session_id = data.get("session_id")
    seat_ids = data.get("seat_ids", [])

    if not session_id or not seat_ids:
        return jsonify({"error": "session_id ve seat_ids zorunludur"}), 400

    session = Session.query.get(session_id)
    if not session:
        return jsonify({"error": "Seans bulunamadı"}), 404

    valid_seats = Seat.query.filter(
        Seat.id.in_(seat_ids),
        Seat.hall_id == session.hall_id
    ).all()

    if len(valid_seats) != len(seat_ids):
        return jsonify({"error": "Bazı koltuklar geçersiz veya bu salona ait değil"}), 400

    #  TEMBEL TEMİZLİK (Lazy Cleanup)
    expire_time = datetime.utcnow() - timedelta(minutes=10)
    expired_reservations = Reservation.query.filter(
        Reservation.session_id == session_id,
        Reservation.status == "pending",
        Reservation.locked_at < expire_time
    ).all()
    
    for exp_res in expired_reservations:
        db.session.delete(exp_res)
    db.session.commit()

    #  KOLTUK KONTROLÜ: Satın alınmış (completed) VEYA hala birinin sepetinde (pending) olanları bul
    active_reservations = Reservation.query.filter(
        Reservation.session_id == session_id,
        Reservation.status.in_(["completed", "pending"])
    ).all()

    occupied_seat_ids = set()
    for reservation in active_reservations:
        for rs in reservation.reserved_seats:
            occupied_seat_ids.add(rs.seat_id)

    conflicted = [seat_id for seat_id in seat_ids if seat_id in occupied_seat_ids]
    if conflicted:
        return jsonify({
            "error": "Üzgünüz, seçtiğiniz koltuklardan bazıları az önce satıldı veya başkası tarafından inceleniyor.",
            "conflicted_seat_ids": conflicted
        }), 409

    total_price = float(session.price) * len(seat_ids)

    # KİLİTLEME İŞLEMİ (pending)
    reservation = Reservation(
        user_id=current_user_id,
        session_id=session.id,
        status="pending",
        total_price=total_price,
        payment_status="unpaid",
        locked_at=datetime.utcnow() #  Kilitlenme süresi başlatıldı
    )

    db.session.add(reservation)
    db.session.flush()

    for seat_id in seat_ids:
        reserved_seat = ReservationSeat(
            reservation_id=reservation.id,
            seat_id=seat_id
        )
        db.session.add(reserved_seat)

    db.session.commit()

    return jsonify({
        "message": "Koltuk(lar) sizin için 10 dakikalığına kilitlendi. Ödeme sayfasına yönlendiriliyorsunuz.",
        "reservation": reservation.to_dict()
    }), 201


@reservation_bp.route("/<int:reservation_id>/pay", methods=["POST"])
@jwt_required()
def simulate_payment(reservation_id):
    current_user_id = int(get_jwt_identity())

    reservation = Reservation.query.get(reservation_id)
    if not reservation:
        return jsonify({"error": "Rezervasyon bulunamadı"}), 404

    if reservation.user_id != current_user_id:
        return jsonify({"error": "Bu rezervasyon size ait değil"}), 403

    if reservation.payment_status == "paid" or reservation.status == "completed":
        return jsonify({"error": "Bu rezervasyon zaten ödenmiş"}), 400
        
    #  SÜRE KONTROLÜ: 10 Dakika doldu mu?
    expire_time = datetime.utcnow() - timedelta(minutes=10)
    if reservation.status == "pending" and reservation.locked_at < expire_time:
        db.session.delete(reservation)
        db.session.commit()
        return jsonify({"error": "Ödeme süresi (10 dakika) dolduğu için koltuklarınız boşa düştü. Lütfen tekrar koltuk seçin."}), 408

    data = request.get_json()
    if not data:
        return jsonify({"error": "JSON veri gönderilmedi"}), 400

    card_holder = data.get("card_holder", "").strip()
    card_number = data.get("card_number", "").strip()
    expiry_date = data.get("expiry_date", "").strip()
    cvv = data.get("cvv", "").strip()

    if not card_holder or not card_number or not expiry_date or not cvv:
        return jsonify({"error": "Kart bilgileri eksik"}), 400

    # Çakışma kontrolüne gerek kalmadı çünkü zaten biz kilitledik!
    # Eğer kilit süresi dolmadıysa o koltuk zaten bizimdir.

    reservation.payment_status = "paid"
    reservation.status = "completed" #  Koltuk satıldı!

    ticket_code = f"TCK-{uuid.uuid4().hex[:10].upper()}"

    seat_labels = []
    for rs in reservation.reserved_seats:
        if rs.seat:
            seat_labels.append(f"{rs.seat.row_label}{rs.seat.seat_number}")

    qr_payload = {
        "ticket_code": ticket_code,
        "reservation_id": reservation.id,
        "user_id": reservation.user_id,
        "session_id": reservation.session_id,
        "movie_title": reservation.session.movie.title if reservation.session and reservation.session.movie else None,
        "hall_name": reservation.session.hall.name if reservation.session and reservation.session.hall else None,
        "start_time": reservation.session.start_time.isoformat() if reservation.session and reservation.session.start_time else None,
        "seats": seat_labels,
        "total_price": reservation.total_price
    }

    ticket = Ticket(
        reservation_id=reservation.id,
        ticket_code=ticket_code,
        qr_data=json.dumps(qr_payload, ensure_ascii=False)
    )

    db.session.add(ticket)
    db.session.commit()

    return jsonify({
        "message": "Ödeme başarılı, bilet oluşturuldu",
        "reservation": reservation.to_dict(),
        "ticket": ticket.to_dict()
    }), 200


@reservation_bp.route("/my", methods=["GET"])
@jwt_required()
def get_my_reservations():
    current_user_id = int(get_jwt_identity())
    
    # Sadece ödemesi tamamlanmış (completed) rezervasyonları listele
    reservations = Reservation.query.filter_by(user_id=current_user_id, status="completed").order_by(Reservation.id.desc()).all()

    result = []
    for reservation in reservations:
        item = reservation.to_dict()
        item["session"] = reservation.session.to_dict() if reservation.session else None
        item["movie"] = reservation.session.movie.to_dict() if reservation.session and reservation.session.movie else None
        item["hall"] = reservation.session.hall.to_dict() if reservation.session and reservation.session.hall else None
        item["seats"] = [rs.to_dict() for rs in reservation.reserved_seats]
        item["ticket"] = reservation.ticket.to_dict() if reservation.ticket else None
        result.append(item)

    return jsonify(result), 200