"""End-to-end test: get a REAL Firebase ID token and verify it."""
import json
import urllib.request

# 1. Sign in via Firebase Auth REST API
API_KEY = "AIzaSyCKRcRsHRtvt4CerNbQzCEBmChD8V6dVr0"
url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
payload = json.dumps({
    "email": "kaipabhaskar4261@gmail.com",
    "password": "1234567",
    "returnSecureToken": True
}).encode()

req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
resp = urllib.request.urlopen(req)
data = json.loads(resp.read())
id_token = data["idToken"]
print(f"Got ID token (len={len(id_token)})")
print(f"Token starts with: {id_token[:50]}...")

# 2. Now verify it with our backend's Firebase Admin SDK
import firebase_admin
from firebase_admin import credentials, auth

try:
    firebase_admin.get_app()
except ValueError:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)

try:
    decoded = auth.verify_id_token(id_token, check_revoked=False)
    print(f"\nToken verification SUCCESS!")
    print(f"UID: {decoded['uid']}")
    print(f"Email: {decoded.get('email')}")
    print(f"Issuer: {decoded.get('iss')}")
    print(f"Audience: {decoded.get('aud')}")
except Exception as e:
    print(f"\nToken verification FAILED: {type(e).__name__}: {e}")

# 3. Also try hitting our backend directly
print("\n--- Testing backend /auth/login ---")
login_url = "http://localhost:8000/auth/login"
login_payload = json.dumps({"uuid": "test-uuid", "device_fingerprint_hash": "test-hash"}).encode()
login_req = urllib.request.Request(
    login_url,
    data=login_payload,
    headers={
        "Authorization": f"Bearer {id_token}",
        "Content-Type": "application/json",
    },
)
try:
    login_resp = urllib.request.urlopen(login_req)
    print(f"Backend response: {login_resp.status}")
    print(json.loads(login_resp.read()))
except urllib.error.HTTPError as e:
    print(f"Backend error: {e.code}")
    print(json.loads(e.read()))
