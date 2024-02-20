import json
import pickle
import threading
import time

from pydantic import BaseModel
from txtai.embeddings import Embeddings
import traceback

from .utils.query import short_query_to_long_passage

from .utils.pos import POSResult
from .logger import logger

from .custom_sqlite.sqlite import SQLite

# from .utils.db import TxtaiDatabase
from .utils.state import (
    get_document_path,
    get_embeddings,
    set_embeddings,
    set_is_deleting,
    state,
)
import re


def remove_symbols(input_string):
    # Define a regular expression pattern to match symbols (non-alphanumeric and non-whitespace characters)
    pattern = r"[^a-zA-Z0-9\s]"

    # Use the re.sub() function to replace matched symbols with an empty string
    cleaned_string = re.sub(pattern, "", input_string)

    return cleaned_string


memory_lock = threading.RLock()

deleting = False


class Embedding:
    path: str
    instance: Embeddings

    def __init__(self, embeddings=None):
        self.instance = (
            embeddings
            if embeddings is not None
            else Embeddings(
                method="sentence-transformers",
                path="BAAI/bge-small-en",
                content="src.custom_sqlite.sqlite.SQLite",
                hybrid=True,
                gpu=False,
                # functions=[{"name": "graph", "function": "graph.attribute"}],
                # expressions=[
                #     {"name": "topic", "expression": "graph(indexid, 'topic')"},
                #     {"name": "topicrank", "expression": "graph(indexid, 'topicrank')"},
                # ],
                # graph={"topics": {}},
            )
        )
        document_path = get_document_path()
        if not document_path:
            return
        self.path = f"{document_path}/txtai"
        self.instance.load(self.path)

    def persist(self):
        self.instance.save(self.path)


def get_embedding():
    state_embeddings = get_embeddings()
    if state_embeddings:
        return state_embeddings

    embedding = Embedding()
    set_embeddings(embedding)
    return embedding


def get_tags():
    global memory_lock
    embedding = get_embedding()
    if not embedding:
        return []

    with memory_lock:
        app_names = embedding.instance.search(
            "select distinct app_name from txtai limit 300"
        )

    return [
        {"id": f"content_type#meeting", "type": "content_type", "value": "Meeting"}
    ] + [
        {"id": f"app_name#{x['app_name']}", "type": "app_name", "value": x["app_name"]}
        for x in app_names
    ]


def get_transcription(path: str):
    global memory_lock
    embedding = get_embedding()
    if not embedding:
        return []

    with memory_lock:
        memories = embedding.instance.database.query_raw(
            f"""
            select s.id, s.text, json_extract(d.data, '$.meta') as tags 
            from sections s
            LEFT JOIN documents d ON s.id = d.id 
            where path='{path}' and is_transcription=1
            """
        )

    for memory in memories:
        memory["tags"] = json.loads(memory["tags"])
    return memories


def memory_search(
    query: str,
    tags: str | None = None,
    date_condition: POSResult | None = None,
):
    global memory_lock

    embedding = get_embedding()
    if not embedding:
        return {}

    query = (
        date_condition.clean_text
        if date_condition and date_condition.clean_text
        else query
    )

    weights = 0.5
    if short_query_to_long_passage(query):
        weights = 1
        query = f"Represent this sentence for searching relevant passages: {query}"

    date_filter = None
    if date_condition:
        date_type = date_condition.range_type
        date_reference = date_condition.parsed_date
        if date_type == "after":
            date_filter = (
                f"captured_at >= '{date_reference.strftime('%Y-%m-%dT00:00:00.000')}'"
            )
        elif date_type == "before":
            date_filter = (
                f"captured_at <= '{date_reference.strftime('%Y-%m-%dT00:00:00.000')}'"
            )
        elif date_type == "range_week":
            date_filter = f"captured_at between '{date_condition.from_date.strftime('%Y-%m-%dT00:00:00.000')}' and '{date_condition.to_date.strftime('%Y-%m-%dT00:00:00.000')}'"
        elif date_type == "range_month":
            date_filter = f"captured_at between '{date_condition.from_date.strftime('%Y-%m-%dT00:00:00.000')}' and '{date_condition.to_date.strftime('%Y-%m-%dT00:00:00.000')}'"
        elif date_type == "range_year":
            date_filter = f"captured_at between '{date_condition.from_date.strftime('%Y-%m-%dT00:00:00.000')}' and '{date_condition.to_date.strftime('%Y-%m-%dT00:00:00.000')}'"
        elif date_type == "exact":
            date_filter = f"captured_at like '{date_reference.strftime('%Y-%m-%d')}%'"

    app_name_filters = []
    content_type = ""

    for memory_tag in json.loads(tags):
        if memory_tag["type"] == "app_name":
            app_name_filters.append(f"'{memory_tag['value']}'")
        if memory_tag["type"] == "content_type":
            content_type = memory_tag["value"]
        if memory_tag["type"] == "date_between":
            d1, d2 = memory_tag["value"].split("#")
            date_filter = f"captured_at between '{d1}' and '{d2}'"

    where = "similar('{q}') and score > 0.25".format(q=query) if query else "1=1"
    if date_filter:
        where += f" and {date_filter}\n"
    if content_type == "Meeting":
        where += " and is_transcription=1\n"

    if len(app_name_filters) > 0:
        where += f" and app_name in ({','.join(set(app_name_filters))})"

    query = """
        select text, score, json_group_array(meta) as rows
        from txtai
        where {where}
        group by text
        order by score desc
        limit {limit}
        """.format(
        where=where,
        limit=20 * 8,
    )

    with memory_lock:
        t0 = time.time()
        search_result = embedding.instance.search(query, weights=weights)
        t1 = time.time()
        logger.info(f"searching took {t1-t0} seconds")

    return search_result


def remove_memory(date: str):
    global deleting

    embedding = get_embedding()
    if not embedding:
        return {}
    try:
        set_is_deleting(True)
        with memory_lock:
            result = embedding.instance.database.query_raw(
                f"select id from sections where captured_at < '{date}'"
            )
            result = [x["id"] for x in result]
            logger.info(f"deleting {len(result)} results before date {date}")
            if len(result) > 0:
                embedding.instance.delete(result)
                embedding.persist()
        logger.info(f"deleted {len(result)} results before date {date}")
    except Exception as e:
        logger.error(f"failed to delete memory {traceback.format_exc()}")

    set_is_deleting(False)


class Memory(BaseModel):
    id: str
    text: str
    app_name: str
    window_name: str
    captured_at: str
    location: list[float]
    screenshot_path: str
    screenshot_time: float
    screenshot_time_to: float | None
    screenshot_minX: float | None  # None for regression
    screenshot_minY: float | None  # None for regression
    screenshot_width: float
    screenshot_height: float
    url: str | None

    def from_memory(memory):
        return Memory(
            id=memory.id,
            text=memory.text,
            app_name=memory.app_name,
            window_name=memory.window_name,
            captured_at=memory.captured_at,
            location=memory.location,
            screenshot_path=memory.screenshot_path,
            screenshot_time=memory.screenshot_time,
            screenshot_time_to=memory.screenshot_time_to,
            screenshot_minX=memory.screenshot_minX,
            screenshot_minY=memory.screenshot_minY,
            screenshot_width=memory.screenshot_width,
            screenshot_height=memory.screenshot_height,
            url=memory.url,
        )


class StoreMemory:
    memories: list[Memory]

    def __init__(self):
        self.memories = []

    def ready(self):
        return get_embedding() is not None

    def add_memories(self, documents: list[Memory]):
        self.memories += documents

    def persist(self):
        global memory_lock
        embedding = get_embedding()
        if not embedding:
            return

        docs = [
            (
                x.id,
                {
                    "text": x.text,
                    "meta": json.dumps(
                        {
                            "captured_at": x.captured_at,
                            "location": x.location,
                            "path": x.screenshot_path,
                            "time": x.screenshot_time,
                            "time_to": x.screenshot_time_to,
                            "minX": x.screenshot_minX,
                            "minY": x.screenshot_minY,
                            "width": x.screenshot_width,
                            "height": x.screenshot_height,
                            "app_name": x.app_name,
                            "window_name": x.window_name,
                            "is_transcription": x.screenshot_time_to is not None,
                            "url": x.url,
                        }
                    ),
                },
                None,
            )
            for x in self.memories
        ]

        if len(docs) == 0:
            return

        with memory_lock:
            try:
                t0 = time.time()
                embedding.instance.upsert(docs)
                t1 = time.time()
                logger.info(
                    f"indexing {len(docs)} docs took {t1 - t0} seconds, {len(docs) / (t1 - t0)} docs per second"
                )
                embedding.persist()
                logger.info(
                    f"persisting {len(docs)} docs took {time.time() - t1} seconds"
                )
            except Exception as e:
                logger.error(f"failed to persist memory {traceback.format_exc()}")
