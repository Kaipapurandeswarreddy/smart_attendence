import asyncio
import os
from google.cloud import firestore_v1

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "serviceAccountKey.json"

async def main():
    print("Connecting to Firestore...")
    db = firestore_v1.AsyncClient(database="default")
    try:
        col = db.collection("classrooms")
        docs = col.stream()
        print("Successfully connected! Documents:")
        async for doc in docs:
            print(doc.id, "=>", doc.to_dict())
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(main())
