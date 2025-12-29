import firebase_admin
from firebase_admin import credentials, auth
from app.core.config import settings


def init_firebase():
    if firebase_admin._apps:
        return firebase_admin.get_app()

    if settings.firebase_credentials_path:
        cred = credentials.Certificate(settings.firebase_credentials_path)
        return firebase_admin.initialize_app(cred)

    # initialize with default application credentials if available
    return firebase_admin.initialize_app()


# initialize at import time
init_firebase()
