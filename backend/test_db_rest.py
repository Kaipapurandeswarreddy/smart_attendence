import json
import urllib.request
from google.oauth2 import service_account
from google.auth.transport.requests import Request

def get_databases():
    cred = service_account.Credentials.from_service_account_file(
        "serviceAccountKey.json",
        scopes=["https://www.googleapis.com/auth/cloud-platform"]
    )
    cred.refresh(Request())
    
    url = "https://firestore.googleapis.com/v1/projects/smart-attendance-system-44930/databases"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {cred.token}")
    
    try:
        response = urllib.request.urlopen(req)
        data = json.loads(response.read())
        print("Databases found:", json.dumps(data, indent=2))
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code}")
        print(e.read().decode())

if __name__ == "__main__":
    get_databases()
