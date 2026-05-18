"""Quick diagnostic: test Firebase ID token verification end-to-end."""

import firebase_admin
from firebase_admin import credentials, auth as firebase_auth

# Init (may already be initialised by import chain)
try:
    app = firebase_admin.get_app()
except ValueError:
    cred = credentials.Certificate("serviceAccountKey.json")
    app = firebase_admin.initialize_app(cred)

print("=== Firebase Admin SDK Info ===")
print(f"Project ID: {app.project_id}")
print(f"Service Account: {app.credential.service_account_email}")
print()

# List the user we're testing
email = "kaipabhaskar4261@gmail.com"
try:
    user = firebase_auth.get_user_by_email(email)
    print(f"User: {user.uid} | {user.email}")
    print(f"Provider: {user.provider_id}")
    print(f"Disabled: {user.disabled}")
    print(f"Email verified: {user.email_verified}")
    print(f"Custom claims: {user.custom_claims}")
    print()
except Exception as e:
    print(f"Error getting user: {e}")
    exit(1)

# Check if we can verify tokens at all
# Create a custom token (this doesn't give us an ID token, but tests SDK)
try:
    custom = firebase_auth.create_custom_token(user.uid)
    print(f"Custom token creation: OK (len={len(custom)})")
except Exception as e:
    print(f"Custom token creation FAILED: {e}")

# Check the service account key project ID matches
import json
with open("serviceAccountKey.json") as f:
    sa = json.load(f)
print(f"\nService Account Key project_id: {sa.get('project_id')}")
print(f"Firebase App project_id: {app.project_id}")
if sa.get("project_id") != app.project_id:
    print("⚠️  PROJECT ID MISMATCH!")
else:
    print("✅ Project IDs match")

# Check certificates endpoint
import urllib.request
try:
    resp = urllib.request.urlopen(
        "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com",
        timeout=5,
    )
    data = json.loads(resp.read())
    print(f"\n✅ Google public keys fetched: {len(data)} keys available")
except Exception as e:
    print(f"\n❌ Cannot fetch Google public keys: {e}")
    print("   This would cause ALL token verification to fail!")
