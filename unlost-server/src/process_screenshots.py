from typing import cast
from src.memory import Memory, StoreMemory
from src.utils.db import ScreenshotDatabase
from src.logger import logger
from src.utils.state import (
    get_migration_state,
    set_last_client_timestamp,
    get_document_path,
    get_is_client_open,
    get_is_client_open_for_more_than_1_minute,
    state,
)
import faulthandler
from json import loads
from os import path
import traceback
from threading import Thread

from src.utils.transform_memory import transform_memory

faulthandler.enable()


import threading

lock = threading.Lock()


def process_screenshots():
    global lock

    if lock.locked():
        logger.info("already processing")
        return

    if get_is_client_open():
        logger.debug("client is open")
        if get_is_client_open_for_more_than_1_minute():
            logger.warn("client is open for more than 1 minute, shouldn't happen")
            set_last_client_timestamp(False)
        else:
            logger.debug("client is open, not processing")
            return

    process_more = False
    with lock:
        try:
            process_more = process_screenshots_inner()
        except Exception as e:
            logger.error(f"failed to process screenshots {traceback.format_exc()}")
        finally:
            logger.info("done processing")

    if process_more:
        Thread(target=process_screenshots).start()


def process_screenshots_inner():
    logger.info("start processing screenshots")

    document_path = get_document_path()
    if not document_path:
        return

    db = state["screenshot_db"]
    if not db:
        return

    if get_migration_state() is not None:
        return

    db = cast(ScreenshotDatabase, db)

    store_memory = StoreMemory()
    if not store_memory.ready():
        return

    screenshots = db.get_screenshots_to_process()
    if len(screenshots) < 5:
        return

    screenshots = [x for x in screenshots if path.exists(get_path(x["path"]))]
    normal_screenshots = []
    transcription_screenshots = []
    for screenshot in screenshots:
        if screenshot["is_transcription"]:
            transcription_screenshots.append(screenshot)
        else:
            normal_screenshots.append(screenshot)

    logger.info(
        f"processing {len(normal_screenshots)} screenshots, {len(transcription_screenshots)} transcriptions"
    )

    for screenshot in transcription_screenshots:
        store_memory.add_memories(
            [
                Memory(
                    id=f"transcription#{'mic' if screenshot['is_mic'] else 'audio'}#{screenshot['id']}",
                    text=screenshot["ocr_result"],
                    app_name=screenshot["app_name"],
                    window_name=screenshot["app_title"],
                    captured_at=screenshot["created_at"],
                    location=[],
                    screenshot_path=get_relative_path(screenshot["path"]),
                    screenshot_time=float(screenshot["screenshot_time"]),
                    screenshot_time_to=float(screenshot["screenshot_time_to"]),
                    screenshot_minX=screenshot["minX"],
                    screenshot_minY=screenshot["minY"],
                    screenshot_width=screenshot["width"],
                    screenshot_height=screenshot["height"],
                    url=screenshot["url"],
                )
            ]
        )

    for screenshot in normal_screenshots:
        memories = transform_memory(
            [
                Memory(
                    id=f'{screenshot["id"]}#{i}',
                    text=x["value"],
                    app_name=screenshot["app_name"],
                    window_name=screenshot["app_title"],
                    captured_at=screenshot["created_at"],
                    location=x["location"],
                    screenshot_path=get_relative_path(screenshot["path"]),
                    screenshot_time=float(screenshot["screenshot_time"]),
                    screenshot_time_to=None,
                    screenshot_minX=screenshot["minX"],
                    screenshot_minY=screenshot["minY"],
                    screenshot_width=screenshot["width"],
                    screenshot_height=screenshot["height"],
                    url=screenshot["url"],
                )
                for i, x in enumerate(loads(screenshot["ocr_result"]))
                if len(x["value"]) > 1
            ]
        )
        store_memory.add_memories(memories)

    # persist
    store_memory.persist()

    # delete db records
    db.delete_screenshots([x["id"] for x in screenshots])

    return db.has_more_screenshots_to_process()


def get_path(path: str):
    return path.replace("\\", "").replace("file://", "")[1:-1]


def get_relative_path(path: str):
    return get_path(path).replace(get_document_path(), "")
