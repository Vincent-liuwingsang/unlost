import logging
import traceback
import os
from fastapi import Request
from logging.handlers import TimedRotatingFileHandler

formatter = logging.Formatter(
    "%(asctime)s %(levelname)-8s %(message)s", "%Y-%m-%d %H:%M:%S"
)

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("unlost_server")
sh = logging.StreamHandler()
sh.setFormatter(formatter)
logger.addHandler(logging.StreamHandler())


async def catch_exceptions_middleware(request: Request, call_next):
    global logger
    try:
        return await call_next(request)
    except Exception as e:
        logger.error(traceback.format_exc())
        raise e


added_logger = False


def set_logger_path(path: str):
    global logger, added_logger

    log_directory = f"{path}/logs/server"
    log_path = f"{log_directory}/logs.txt"

    if added_logger:
        return log_path

    remove_legacy_log(f"{path}/logs/unlost_server.log")
    if not os.path.exists(log_directory):
        os.makedirs(log_directory)

    fh = logging.FileHandler(log_path)
    fh = TimedRotatingFileHandler(log_path, when="d", interval=1, backupCount=3)
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(formatter)
    logger.addHandler(fh)
    added_logger = True
    return log_path


def remove_legacy_log(path: str):
    try:
        os.remove(path)
    except OSError:
        pass
