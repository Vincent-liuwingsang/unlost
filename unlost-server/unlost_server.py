from multiprocessing import freeze_support
from os import getpid
from sys import argv

from uvicorn import run
from fastapi import FastAPI
from psutil import Process
from fastapi_utils.tasks import repeat_every

from src.process_screenshots import process_screenshots
from src.memory import get_tags, get_transcription, memory_search, remove_memory
from src.logger import catch_exceptions_middleware, set_logger_path
from src.utils.state import (
    get_is_deleting,
    get_migration_state,
    set_document_path,
    set_last_client_timestamp,
)
from src.utils.pos import get_date_condition

app = FastAPI()

app.middleware("http")(catch_exceptions_middleware)

# parent_queue = None


def i_quit():
    parent_pid = getpid()
    parent = Process(parent_pid)
    for child in parent.children(recursive=True):
        child.kill()
    parent.kill()


@app.post("/kill")
def kill_api():
    if get_is_deleting():
        return
    if get_migration_state() is not None:
        return

    i_quit()
    # parent_queue.put({"type": "command", "value": "kill"}, False)


@app.get("/transcriptions")
def get_transcription_api(path: str):
    return get_transcription(path)


@app.get("/memory")
def get_memory_api(query: str, tags: str | None = None, offset: int = 0):
    if get_migration_state() is not None:
        return {"memories": [], "scanned_count": 0, "date_condition": None}

    clean_query = query.replace("'", "").replace(";", "")
    date_condition = None
    if "date_between" not in tags:
        date_condition = get_date_condition(clean_query)

    memories = memory_search(clean_query, tags, date_condition)

    if date_condition:
        date_condition.from_date = date_condition.from_date.strftime(
            "%Y-%m-%dT%H:%M:%S"
        )
        date_condition.to_date = date_condition.to_date.strftime("%Y-%m-%dT%H:%M:%S")
    return {"memories": memories, "scanned_count": 0, "date_condition": date_condition}
    # return {"memories": [], "scanned_count": 0, "date_condition": date_condition}


@app.delete("/memory")
def delete_memory_api(date: str):
    remove_memory(date)


@app.get("/tags")
def get_tags_api():
    if get_migration_state() is not None:
        raise Exception("migrating")
    return get_tags()


@app.post("/test")
def test_api():
    process_screenshots()
    return True


@app.get("/ping")
def ping_api(client_open: bool | None):
    if client_open is not None:
        set_last_client_timestamp(client_open)

    return True


@app.get("/state")
def state_api():
    if get_migration_state() is not None:
        return "migrating"

    if get_is_deleting():
        return "deleting"

    return "running"


@app.on_event("startup")
@repeat_every(seconds=60)
def process_screenshots_cron():
    process_screenshots()


def run_api_server(doc_path=""):
    if doc_path:
        set_document_path(doc_path)
        set_logger_path(doc_path)

    run(app, host="0.0.0.0", port=58000)


if __name__ == "__main__":
    freeze_support()
    get_date_condition("test")
    run_api_server(doc_path=argv[1])
