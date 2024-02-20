from datetime import datetime
from .db import ScreenshotDatabase
import en_core_web_sm
import spacy

state = {
    "document_path": "",
    "screenshot_db": None,
    "txtai_db": None,
    "embeddings": None,
    "last_client_opened_at": 0,
    "last_client_closed_at": 0,
    "deleting": False,
    "migration": None,
    "nlp": en_core_web_sm.load(),
}


def get_nlp():
    return state["nlp"]


def set_embeddings(embeddings):
    state["embeddings"] = embeddings


def get_embeddings():
    return state["embeddings"]


def set_migration_state(key: str):
    state["migration"] = key


def remove_migration_state():
    state["migration"] = None


def get_migration_state():
    return state["migration"]


def get_is_deleting():
    return state["deleting"]


def set_is_deleting(is_deleting: bool):
    state["deleting"] = is_deleting


def get_document_path():
    return state["document_path"]


def set_document_path(path: str):
    state["document_path"] = path
    if state["document_path"] and not state["screenshot_db"]:
        state["screenshot_db"] = ScreenshotDatabase(state["document_path"])


def set_last_client_timestamp(is_open: bool):
    state[
        "last_client_opened_at" if is_open else "last_client_closed_at"
    ] = datetime.now().timestamp()


def get_is_client_open():
    return state["last_client_opened_at"] > state["last_client_closed_at"]


def get_is_client_open_for_more_than_1_minute():
    return datetime.now().timestamp() - state["last_client_opened_at"] > 60
