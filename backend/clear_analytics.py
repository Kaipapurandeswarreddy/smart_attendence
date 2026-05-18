import asyncio
from firebase_client import db
from models.attendance import COLLECTION as RECORDS_COLLECTION

async def clear_analytics():
    docs = db.collection(RECORDS_COLLECTION).stream()
    count = 0
    async for doc in docs:
        await doc.reference.delete()
        count += 1
    print(f"Deleted {count} attendance records.")

if __name__ == "__main__":
    asyncio.run(clear_analytics())
