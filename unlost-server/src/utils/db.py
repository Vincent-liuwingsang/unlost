from sqlite3 import Connection, Cursor, connect
from datetime import datetime


class ScreenshotDatabase:
    connection: Connection
    cursor: Cursor

    CREATE_MIGRATIONS = """
        CREATE TABLE IF NOT EXISTS migrations (
            id TEXT PRIMARY KEY,
            key TEXT,
            last_processed DATETIME,
            done INTEGER DEFAULT 0
        )
    """

    def __init__(self, document_path: str):
        self.connection = connect(
            f"{document_path}/db.sqlite3", check_same_thread=False
        )
        self.connection.execute("PRAGMA journal_mode=WAL")
        self.cursor = self.connection.cursor()
        self.create_migration_table()

    def __del__(self):
        self.connection.commit()
        self.cursor.close()
        self.connection.close()

    def create_migration_table(self):
        self.cursor.execute(self.CREATE_MIGRATIONS)

    def create_migration(self, key: str):
        query = f"""
        INSERT INTO migrations(key, last_processed, done) 
        SELECT '{key}', '{datetime.now()}', 0 
        WHERE NOT EXISTS (SELECT 1 FROM migrations WHERE key='{key}')
        """
        self.cursor.execute(query)
        self.connection.commit()

    def update_migration(self, key: str):
        query = f"UPDATE migrations SET last_processed = '{datetime.now()}' WHERE key = '{key}'"
        self.cursor.execute(query)
        self.connection.commit()

    def set_migration(self, key: str, value: int):
        query = f"UPDATE migrations SET done = {value} WHERE key = '{key}'"
        self.cursor.execute(query)
        self.connection.commit()

    def get_migration(self, key: str) -> bool:
        query = f"SELECT done FROM migrations WHERE key = '{key}'"
        result = self.cursor.execute(query)
        done = result.fetchone()
        return done is not None and done[0] == 1

    def get_screenshots_to_process(self):
        query = "SELECT * FROM screenshots WHERE has_ocr_result = 1 ORDER BY created_at asc LIMIT 50"
        self.cursor.execute(query)
        columns = [c[0] for c in self.cursor.description]
        results = []

        for row in self.cursor:
            result = {}

            # Copy columns to result. In cases with duplicate column names, find one with a value
            for x, column in enumerate(columns):
                if column not in result or result[column] is None:
                    result[column] = row[x]

            results.append(result)
        return results

    def has_more_screenshots_to_process(self):
        query = "SELECT count(*) FROM screenshots WHERE has_ocr_result = 1"
        result = self.cursor.execute(query)
        count = result.fetchone()
        print("count", count)
        return count[0] > 0

    def delete_screenshots(self, ids: list[str]):
        self.cursor.execute(
            f"DELETE FROM screenshots WHERE id IN ({','.join([str(x) for x in ids])})",
        )
        self.connection.commit()
