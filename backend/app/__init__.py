from flask import Flask
from flask_cors import CORS

from app.config import Config
from app.extensions import db, migrate, jwt
from app import models
from app.routes.auth_routes import auth_bp
from app.routes.movie_routes import movie_bp
from app.routes.hall_routes import hall_bp
from app.routes.session_routes import session_bp
from app.routes.reservation_routes import reservation_bp
from app.routes.ticket_routes import ticket_bp


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    CORS(app)

    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)

    app.register_blueprint(auth_bp)
    app.register_blueprint(movie_bp)
    app.register_blueprint(hall_bp)
    app.register_blueprint(session_bp)
    app.register_blueprint(reservation_bp)
    app.register_blueprint(ticket_bp)

    @app.route("/")
    def home():
        return {"message": "Backend çalışıyor"}

    return app