"""
Firebase Admin SDK initialisation and Firestore helper utilities.
"""

from __future__ import annotations

from typing import Any

import firebase_admin
from firebase_admin import auth as firebase_auth, credentials, firestore
from google.cloud.firestore_v1 import AsyncClient

from config import FIREBASE_CREDENTIALS_PATH

# ---------------------------------------------------------------------------
# Initialise Firebase Admin SDK (runs once at import time)
# ---------------------------------------------------------------------------
_cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
firebase_admin.initialize_app(_cred)

# Async Firestore client
db: AsyncClient = firestore.AsyncClient(database="default")

# Re-export auth module for convenience
auth = firebase_auth


# ---------------------------------------------------------------------------
# Generic Firestore helpers
# ---------------------------------------------------------------------------

async def get_document(collection: str, doc_id: str) -> dict[str, Any] | None:
    """Return document data or None if it does not exist."""
    ref = db.collection(collection).document(doc_id)
    snap = await ref.get()
    return snap.to_dict() if snap.exists else None


async def set_document(
    collection: str, doc_id: str, data: dict[str, Any]
) -> None:
    """Create or overwrite a document."""
    ref = db.collection(collection).document(doc_id)
    await ref.set(data)


async def update_document(
    collection: str, doc_id: str, data: dict[str, Any]
) -> None:
    """Merge-update fields on an existing document."""
    ref = db.collection(collection).document(doc_id)
    await ref.update(data)


async def query_collection(
    collection: str, field: str, operator: str, value: Any
) -> list[dict[str, Any]]:
    """Run a single-field query and return matching documents."""
    ref = db.collection(collection)
    query = ref.where(field, operator, value)
    results = []
    async for doc in query.stream():
        data = doc.to_dict()
        data["_id"] = doc.id
        results.append(data)
    return results


async def delete_document(collection: str, doc_id: str) -> None:
    """Delete a document by ID."""
    ref = db.collection(collection).document(doc_id)
    await ref.delete()


async def add_document(collection: str, data: dict[str, Any]) -> str:
    """Add a document with an auto-generated ID; return the new ID."""
    _, ref = await db.collection(collection).add(data)
    return ref.id
