import firebase_admin
from firebase_admin import credentials, auth

cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)

users = auth.list_users()
for u in users.users:
    print(f"{u.uid} | {u.email}")
