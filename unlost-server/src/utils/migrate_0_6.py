import shutil
import threading
import traceback
from ..logger import logger
from .state import (
    get_document_path,
    remove_migration_state,
    set_embeddings,
    set_migration_state,
    state,
)
from ..memory import Memory, get_embedding as get_old_embeddings, Embedding
from .transform_memory import transform_memory
import json
import time
from txtai.embeddings import Embeddings
import gc

migrate_0_6_lock = threading.RLock()
migrate_0_6_key = "0.6.0"

migrated_fully = False


def get_path(document_path: str):
    return f"{document_path}/txtai_{migrate_0_6_key}"


def get_embeddings():
    document_path = get_document_path()
    if not document_path:
        return
    embeddings = Embeddings(
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

    path = get_path(document_path)
    if embeddings.exists(path):
        embeddings.load(path)

    return embeddings, path


def migrate_0_6():
    global migrated_fully

    db = state["screenshot_db"]
    if not db:
        return

    db.create_migration(migrate_0_6_key)
    init_temp_tables()
    # memory
    if migrated_fully:
        return

    # disk
    if db.get_migration(migrate_0_6_key):
        migrated_fully = True
        logger.info(f"already migrated ${migrate_0_6_key}")
        return

    set_migration_state(migrate_0_6_key)
    embeddings, path = get_embeddings()
    run_migration(embeddings, path)


def get_next_batch():
    old_embeddings = get_old_embeddings()
    if not old_embeddings.instance.count():
        return []

    q = """
    select  *
    from expanded_docs
    limit 50
    """

    # print(old_embeddings.instance.database.query_raw(q)[0]["rows"])
    return old_embeddings.instance.database.query_raw(q)


def success(db):
    global migrated_fully

    embeddings, path = get_embeddings()

    del state["embeddings"]
    gc.collect()

    document_path = get_document_path()
    if not document_path:
        return

    embeddings.save(f"{document_path}/txtai")

    logger.info(f"deleting temp model at {path}")
    shutil.rmtree(path)

    db.set_migration(migrate_0_6_key, 1)
    migrated_fully = True
    remove_migration_state()
    set_embeddings(Embedding(embeddings))


def run_migration(embeddings, path):
    global migrate_0_6_lock, migrated_fully

    db = state["screenshot_db"]
    if not db:
        return

    process_more = False
    with migrate_0_6_lock:
        t0 = time.time()
        groups = get_next_batch()
        t1 = time.time()
        print(f"get_next_batch took {t1-t0} seconds")

        if not len(groups):
            success(db)
            return

        try:
            process_more = run_migration_inner(groups, embeddings, path)
            db.update_migration(migrate_0_6_key)
        except Exception as e:
            logger.error(f"failed to run migration {traceback.format_exc()}")
        finally:
            logger.info("done partial migration")

    if process_more:
        threading.Thread(target=run_migration, args=[embeddings, path]).start()


def run_migration_inner(groups, embeddings, path):
    new_memories = []
    old_memories = []
    for group in groups:
        is_transcription = group["is_transcription"]
        transformed_memories, old_memories_id = get_new_memories(
            group, is_transcription
        )
        new_memories += transformed_memories
        old_memories += old_memories_id

    docs = memories_to_docs(new_memories)
    t0 = time.time()
    embeddings.upsert(docs)
    embeddings.save(path)
    t1 = time.time()
    logger.info(
        f"migrate {migrate_0_6_key} indexing {len(docs)} docs took {t1 - t0} seconds, {len(docs) / (t1 - t0)} docs per second"
    )

    old_embeddings = get_old_embeddings()
    for group in groups:
        old_embeddings.instance.database.cursor.execute(
            f"DELETE FROM expanded_docs WHERE path='{group['path']}' and time={group['time']} and is_transcription={group['is_transcription']}"
        )
    old_embeddings.instance.database.connection.commit()

    return True  # process more


def memories_to_docs(memories):
    return [
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
        for x in memories
    ]


def get_new_memories(group, is_transcription):
    old_ids = []
    memories = []
    for row in json.loads(group["rows"]):
        x = json.loads(row["data"])
        meta = json.loads(x["meta"])
        old_ids.append(row["id"])
        memory = Memory(
            id=row["id"],
            text=x["text"],
            app_name=meta["app_name"],
            window_name=meta["window_name"],
            captured_at=meta["captured_at"],
            location=meta["location"],
            screenshot_path=meta["path"],
            screenshot_time=meta["time"],
            screenshot_time_to=meta["time_to"],
            screenshot_minX=meta["minX"] if "minX" in meta else None,
            screenshot_minY=meta["minY"] if "minY" in meta else None,
            screenshot_width=meta["width"],
            screenshot_height=meta["height"],
            url=meta["url"],
        )

        memories.append(memory)

    if is_transcription:
        return memories, old_ids

    return transform_memory(memories), old_ids


def init_temp_tables():
    embeddings = get_old_embeddings()

    q = """CREATE TABLE IF NOT EXISTS expanded_docs AS 
      select 
        json_group_array(json_object('id', id, 'data', data)) as rows,
        json_extract(json_extract(data, '$.meta'), '$.path') as path,
        json_extract(json_extract(data, '$.meta'), '$.time') as time,
        json_extract(json_extract(data, '$.meta'), '$.is_transcription') as is_transcription
      from documents
      group by path, time, is_transcription
    """

    embeddings.instance.database.cursor.execute(q)

    index = "CREATE INDEX IF NOT EXISTS expanded_docs_id1 ON expanded_docs(path, time, is_transcription)"
    embeddings.instance.database.cursor.execute(index)
