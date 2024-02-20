"""
FileDB module
"""

import datetime
import json
from txtai.database import Database


# pylint: disable=R0904
class FileDB(Database):
    """
    Base file database class.
    """

    # Temporary table for working with id batches
    CREATE_BATCH = """
        CREATE TEMP TABLE IF NOT EXISTS batch (
            indexid INTEGER,
            id TEXT,
            batch INTEGER
        )
    """

    DELETE_BATCH = "DELETE FROM batch"
    INSERT_BATCH_INDEXID = "INSERT INTO batch (indexid, batch) VALUES (?, ?)"
    INSERT_BATCH_ID = "INSERT INTO batch (id, batch) VALUES (?, ?)"

    # Temporary table for joining similarity scores
    CREATE_SCORES = """
        CREATE TEMP TABLE IF NOT EXISTS scores (
            indexid INTEGER PRIMARY KEY,
            score REAL
        )
    """

    DELETE_SCORES = "DELETE FROM scores"
    INSERT_SCORE = "INSERT INTO scores VALUES (?, ?)"

    # Documents - stores full content
    CREATE_DOCUMENTS = """
        CREATE TABLE IF NOT EXISTS documents (
            id TEXT PRIMARY KEY,
            data JSON,
            tags TEXT,
            entry DATETIME
        )
    """

    INSERT_DOCUMENT = "INSERT OR REPLACE INTO documents VALUES (?, ?, ?, ?)"
    DELETE_DOCUMENTS = "DELETE FROM documents WHERE id IN (SELECT id FROM batch)"

    # Objects - stores binary content
    CREATE_OBJECTS = """
        CREATE TABLE IF NOT EXISTS objects (
            id TEXT PRIMARY KEY,
            object BLOB,
            tags TEXT,
            entry DATETIME
        )
    """

    INSERT_OBJECT = "INSERT OR REPLACE INTO objects VALUES (?, ?, ?, ?)"
    DELETE_OBJECTS = "DELETE FROM objects WHERE id IN (SELECT id FROM batch)"

    # Sections - stores section text
    CREATE_SECTIONS = """
        CREATE TABLE IF NOT EXISTS %s (
            indexid INTEGER PRIMARY KEY,
            id TEXT,
            text TEXT,
            app_name TEXT,
            window_name TEXT,
            captured_at TEXT,
            path TEXT,
            tags TEXT,
            is_transcription INTEGER,
            entry DATETIME
        )
    """

    CREATE_SECTIONS_INDEX = (
        "CREATE INDEX section_id ON sections(id, app_name, window_name, captured_at)"
    )
    CREATE_SECTIONS_PATH_INDEX = (
        "CREATE INDEX section_path_id ON sections(path, is_transcription)"
    )
    INSERT_SECTION = "INSERT INTO sections VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    DELETE_SECTIONS = "DELETE FROM sections WHERE id IN (SELECT id FROM batch)"
    COPY_SECTIONS = (
        "INSERT INTO %s SELECT (select count(*) - 1 from sections s1 where s.indexid >= s1.indexid) indexid, "
        + "s.id, %s AS text, s.app_name AS text, s.window_name AS text, s.captured_at AS text, s.path AS text, s.is_transcription,  s.tags, s.entry FROM sections s LEFT JOIN documents d ON s.id = d.id ORDER BY indexid"
    )
    STREAM_SECTIONS = "SELECT s.id, s.text, s.app_name, s.window_name, s.captured_at, s.path, s.is_transcription, s.tags FROM %s s LEFT JOIN objects o ON s.id = o.id ORDER BY indexid"
    DROP_SECTIONS = "DROP TABLE sections"
    RENAME_SECTIONS = "ALTER TABLE %s RENAME TO sections"

    # Queries
    SELECT_IDS = "SELECT indexid, id FROM sections WHERE id in (SELECT id FROM batch)"
    COUNT_IDS = "SELECT count(indexid) FROM sections"

    # Partial sql clauses
    TABLE_CLAUSE = (
        "SELECT %s FROM sections s "
        + "LEFT JOIN documents d ON s.id = d.id "
        + "LEFT JOIN objects o ON s.id = o.id "
        + "LEFT JOIN scores sc ON s.indexid = sc.indexid"
    )
    IDS_CLAUSE = "s.indexid in (SELECT indexid from batch WHERE batch=%s)"

    # EXTERNAL_TABLE = "sections"
    # EXTERNAL_TABLE_ID = "indexid"
    # FTS_TABLE = "sections_fts"

    # DROP_FTS_SCRIPTS = [
    #     f"DROP TRIGGER IF EXISTS {EXTERNAL_TABLE}_ai",
    #     f"DROP TRIGGER IF EXISTS {EXTERNAL_TABLE}_ad",
    #     f"DROP TRIGGER IF EXISTS {EXTERNAL_TABLE}_au",
    #     f"DROP TABLE IF EXISTS {FTS_TABLE}",
    # ]

    # CREATE_FTS_SCRIPTS = [
    #     f"""
    #     CREATE VIRTUAL TABLE IF NOT EXISTS {FTS_TABLE} USING fts5(
    #         text,
    #         app_name,
    #         window_name,
    #         captured_at,
    #         tags UNINDEXED,
    #         content='{EXTERNAL_TABLE}',
    #         content_rowid='{EXTERNAL_TABLE_ID}',
    #         prefix='7 10'
    #     )
    #     """,
    #     f"""
    #     CREATE TRIGGER {EXTERNAL_TABLE}_ai AFTER INSERT ON {EXTERNAL_TABLE}
    #         BEGIN
    #             INSERT INTO {FTS_TABLE} (rowid, text, app_name, window_name, captured_at, tags)
    #             VALUES (new.{EXTERNAL_TABLE_ID}, new.text, new.app_name, new.window_name, new.captured_at, new.tags);
    #         END;
    #     """,
    #     f"""
    #     CREATE TRIGGER {EXTERNAL_TABLE}_ad AFTER DELETE ON {EXTERNAL_TABLE}
    #         BEGIN
    #             INSERT INTO {FTS_TABLE} ({FTS_TABLE}, rowid, text, app_name, window_name, captured_at, tags)
    #             VALUES ('delete', old.{EXTERNAL_TABLE_ID}, old.text, old.app_name, old.window_name, old.captured_at, old.tags);
    #         END
    #     """,
    #     f"""
    #     CREATE TRIGGER {EXTERNAL_TABLE}_au AFTER UPDATE ON {EXTERNAL_TABLE}
    #         BEGIN
    #             INSERT INTO {FTS_TABLE} ({FTS_TABLE}, rowid, text, app_name, window_name, captured_at, tags)
    #             VALUES ('delete', old.{EXTERNAL_TABLE_ID}, old.text, old.app_name, old.window_name, old.captured_at, old.tags);
    #             INSERT INTO {FTS_TABLE} (rowid, text, app_name, window_name, captured_at, tags)
    #             VALUES (new.{EXTERNAL_TABLE_ID}, new.text, new.app_name, new.window_name, new.captured_at, new.tags);
    #         END
    #     """,
    #     f"INSERT INTO {FTS_TABLE}(rowid, text, app_name, window_name, captured_at, tags) SELECT indexid, text, app_name, window_name, captured_at, tags FROM {EXTERNAL_TABLE}",
    # ]

    def __init__(self, config):
        """
        Creates a new Database.

        Args:
            config: database configuration parameters
        """

        super().__init__(config)

        # Database connection handle
        self.connection = None
        self.cursor = None
        self.path = None

    def load(self, path):
        # Load an existing database. Thread locking must be handled externally.
        self.connection = self.connect(path)
        self.cursor = self.getcursor()
        self.path = path

        # Register custom functions
        self.addfunctions()

    def insert(self, documents, index=0):
        # Initialize connection if not open
        self.initialize()

        # Get entry date
        entry = datetime.datetime.now()

        # Insert documents
        for uid, document, tags in documents:
            meta = document["meta"]
            if isinstance(document, dict):
                # Insert document and use return value for sections table
                document = self.insertdocument(uid, document, tags, entry)

            if document is not None:
                if isinstance(document, list):
                    # Join tokens to text
                    document = " ".join(document)
                elif not isinstance(document, str):
                    # If object support is enabled, save object
                    self.insertobject(uid, document, tags, entry)

                    # Clear section text for objects, even when objects aren't inserted
                    document = None

                # Save text section
                self.insertsection(index, uid, document, tags, entry, meta)
                index += 1

    def delete(self, ids):
        if self.connection:
            # Batch ids
            self.batch(ids=ids)

            # Delete all documents, objects and sections by id
            self.cursor.execute(FileDB.DELETE_DOCUMENTS)
            self.cursor.execute(FileDB.DELETE_OBJECTS)
            self.cursor.execute(FileDB.DELETE_SECTIONS)

    def reindex(self, columns=None):
        if self.connection:
            # Working table name
            name = "rebuild"

            # Resolve and build column strings if provided
            select = "text"
            if columns:
                select = "|| ' ' ||".join([self.resolve(c) for c in columns])

            # Create new table to hold reordered sections
            self.cursor.execute(FileDB.CREATE_SECTIONS % name)

            # Copy data over
            self.cursor.execute(FileDB.COPY_SECTIONS % (name, select))

            # Stream new results
            self.cursor.execute(FileDB.STREAM_SECTIONS % name)
            for uid, text, obj, tags in self.rows():
                if not text and self.encoder and obj:
                    yield (uid, self.encoder.decode(obj), tags)
                else:
                    yield (uid, text, tags)

            # Swap as new table
            self.cursor.execute(FileDB.DROP_SECTIONS)
            self.cursor.execute(FileDB.RENAME_SECTIONS % name)
            self.cursor.execute(FileDB.CREATE_SECTIONS_INDEX)
            self.cursor.execute(FileDB.CREATE_SECTIONS_PATH_INDEX)
            # for script in FileDB.DROP_FTS_SCRIPTS:
            #     self.cursor.execute(script)
            # for script in FileDB.CREATE_FTS_SCRIPTS:
            #     self.cursor.execute(script)

    def save(self, path):
        # Temporary database
        if not self.path:
            # Save temporary database
            self.connection.commit()

            # Copy data from current to new
            connection = self.copy(path)

            # Close temporary database
            self.connection.close()

            # Point connection to new connection
            self.connection = connection
            self.cursor = self.getcursor()
            self.path = path

            # Register custom functions
            self.addfunctions()

        # Paths are equal, commit changes
        elif self.path == path:
            self.connection.commit()

        # New path is different from current path, copy data and continue using current connection
        else:
            self.copy(path).close()

    def close(self):
        # Close connection
        if self.connection:
            self.connection.close()

    def ids(self, ids):
        # Batch ids and run query
        self.batch(ids=ids)
        self.cursor.execute(FileDB.SELECT_IDS)

        # Format and return results
        return self.cursor.fetchall()

    def count(self):
        self.cursor.execute(FileDB.COUNT_IDS)
        return self.cursor.fetchone()[0]

    def resolve(self, name, alias=None):
        # Standard column names
        sections = [
            "indexid",
            "id",
            "tags",
            "entry",
            "app_name",
            "window_name",
            "captured_at",
            "path",
            "is_transcription",
        ]
        noprefix = ["data", "object", "score", "text"]

        if name == "PARTITION" or name == "BY":
            return name

        # Alias expression
        if alias:
            # Skip if name matches alias or alias is a standard column name
            if name == alias or alias in sections:
                return name

            # Build alias clause
            return f'{name} as "{alias}"'

        # Resolve expression
        if self.expressions and name in self.expressions:
            return self.expressions[name]

        # Name is already resolved, skip
        if name.startswith("json_extract(data") or any(
            f"s.{s}" == name for s in sections
        ):
            return name

        # Standard columns - need prefixes
        if name.lower() in sections:
            return f"s.{name}"

        # Standard columns - no prefixes
        if name.lower() in noprefix:
            return name

        # Other columns come from documents.data JSON
        return f"json_extract(data, '$.{name}')"

    def embed(self, similarity, batch):
        # Load similarity results id batch
        self.batch(indexids=[i for i, _ in similarity[batch]], batch=batch)

        # Average and load all similarity scores with first batch
        if not batch:
            self.scores(similarity)

        # Return ids clause placeholder
        return FileDB.IDS_CLAUSE % batch

    # pylint: disable=R0912
    def query(self, query, limit):
        # Extract query components
        select = query.get("select", self.defaults())
        where = query.get("where")
        groupby, having = query.get("groupby"), query.get("having")
        orderby, qlimit, offset = (
            query.get("orderby"),
            query.get("limit"),
            query.get("offset"),
        )
        similarity = query.get("similar")

        # Build query text
        query = FileDB.TABLE_CLAUSE % select
        if where is not None:
            query += f" WHERE {where}"
        if groupby is not None:
            query += f" GROUP BY {groupby}"
        if having is not None:
            query += f" HAVING {having}"
        if orderby is not None:
            query += f" ORDER BY {orderby}"

        # Default ORDER BY if not provided and similarity scores are available
        if similarity and orderby is None:
            query += " ORDER BY score DESC"

        # Apply query limit
        if qlimit is not None or limit:
            query += f" LIMIT {qlimit if qlimit else limit}"

            # Apply offset
            if offset is not None:
                query += f" OFFSET {offset}"

        # Clear scores when no similar clauses present
        if not similarity:
            self.scores(None)

        # Runs a user query through execute method, which has common user query handling logic
        self.execute(self.cursor.execute, query)

        # Retrieve column list from query
        columns = [c[0] for c in self.cursor.description]

        # Map results and return
        results = []
        for row in self.rows():
            result = {}

            # Copy columns to result. In cases with duplicate column names, find one with a value
            for x, column in enumerate(columns):
                if column not in result or result[column] is None:
                    # Decode object
                    if self.encoder and column == "object":
                        result[column] = self.encoder.decode(row[x])
                    else:
                        result[column] = row[x]

            results.append(result)
        return results

    def query_raw(self, query):
        self.execute(self.cursor.execute, query)

        # Retrieve column list from query
        columns = [c[0] for c in self.cursor.description]

        # Map results and return
        results = []
        for row in self.rows():
            result = {}

            # Copy columns to result. In cases with duplicate column names, find one with a value
            for x, column in enumerate(columns):
                if column not in result or result[column] is None:
                    # Decode object
                    if self.encoder and column == "object":
                        result[column] = self.encoder.decode(row[x])
                    else:
                        result[column] = row[x]

            results.append(result)
        return results

    def initialize(self):
        """
        Creates connection and initial database schema if no connection exists.
        """

        if not self.connection:
            # Create temporary database. Thread locking must be handled externally.
            self.connection = self.connect()
            self.cursor = self.getcursor()

            # Register custom functions
            self.addfunctions()

            # Create initial schema and indices
            self.cursor.execute(FileDB.CREATE_DOCUMENTS)
            self.cursor.execute(FileDB.CREATE_OBJECTS)
            self.cursor.execute(FileDB.CREATE_SECTIONS % "sections")
            self.cursor.execute(FileDB.CREATE_SECTIONS_INDEX)
            self.cursor.execute(FileDB.CREATE_SECTIONS_PATH_INDEX)
            # for script in FileDB.DROP_FTS_SCRIPTS:
            #     self.cursor.execute(script)
            # for script in FileDB.CREATE_FTS_SCRIPTS:
            #     self.cursor.execute(script)

    def insertdocument(self, uid, document, tags, entry):
        """
        Inserts a document.

        Args:
            uid: unique id
            document: input document
            tags: document tags
            entry: generated entry date

        Returns:
            section value
        """

        # Make a copy of document before changing
        document = document.copy()

        # Get and remove object field from document
        obj = document.pop("object") if "object" in document else None

        # Insert document as JSON
        if document:
            self.cursor.execute(
                FileDB.INSERT_DOCUMENT,
                [uid, json.dumps(document, allow_nan=False), tags, entry],
            )

        # Get value of text field
        text = document.get("text")

        # If both text and object are set, insert object as it won't otherwise be used
        if text and obj:
            self.insertobject(uid, obj, tags, entry)

        # Return value to use for section - use text if available otherwise use object
        return text if text else obj

    def insertobject(self, uid, obj, tags, entry):
        """
        Inserts an object.

        Args:
            uid: unique id
            obj: input object
            tags: object tags
            entry: generated entry date
        """

        # If object support is enabled, save object
        if self.encoder:
            self.cursor.execute(
                FileDB.INSERT_OBJECT, [uid, self.encoder.encode(obj), tags, entry]
            )

    def insertsection(self, index, uid, text, tags, entry, meta):
        """
        Inserts a section.

        Args:
            index: index id
            uid: unique id
            text: section text
            tags: section tags
            entry: generated entry date
        """

        tags_json = json.loads(meta)
        if not tags_json["app_name"]:
            raise Exception("app_name is empty")
        if not tags_json["captured_at"]:
            raise Exception("captured_at is empty")
        if not tags_json["path"]:
            raise Exception("path is empty")

        # Save text section
        self.cursor.execute(
            FileDB.INSERT_SECTION,
            [
                index,
                uid,
                text,
                tags_json["app_name"],
                tags_json["window_name"] or "unknown",
                tags_json["captured_at"],
                tags_json["path"],
                tags,
                1 if tags_json["is_transcription"] else 0,
                entry,
            ],
        )

    def defaults(self):
        """
        Returns a list of default columns when there is no select clause.

        Returns:
            list of default columns
        """

        return "s.id, text, score"

    def batch(self, indexids=None, ids=None, batch=None):
        """
        Loads ids to a temporary batch table for efficient query processing.

        Args:
            indexids: list of indexids
            ids: list of ids
            batch: batch index, used when statement has multiple subselects
        """

        # Create or Replace temporary batch table
        self.cursor.execute(FileDB.CREATE_BATCH)

        # Delete batch when batch id is empty or for batch 0
        if not batch:
            self.cursor.execute(FileDB.DELETE_BATCH)

        if indexids:
            self.cursor.executemany(
                FileDB.INSERT_BATCH_INDEXID, [(i, batch) for i in indexids]
            )
        if ids:
            self.cursor.executemany(
                FileDB.INSERT_BATCH_ID, [(str(uid), batch) for uid in ids]
            )

    def scores(self, similarity):
        """
        Loads a batch of similarity scores to a temporary table for efficient query processing.

        Args:
            similarity: similarity results as [(indexid, score)]
        """

        # Create or Replace temporary scores table
        self.cursor.execute(FileDB.CREATE_SCORES)

        # Delete scores
        self.cursor.execute(FileDB.DELETE_SCORES)

        if similarity:
            # Average scores per id, needed for multiple similar() clauses
            scores = {}
            for s in similarity:
                for i, score in s:
                    if i not in scores:
                        scores[i] = []
                    scores[i].append(score)

            # Average scores by id
            self.cursor.executemany(
                FileDB.INSERT_SCORE, [(i, sum(s) / len(s)) for i, s in scores.items()]
            )

    def connect(self, path=None):
        """
        Creates a new database connection.

        Args:
            path: path to database file

        Returns:
            connection
        """

        raise NotImplementedError

    def getcursor(self):
        """
        Opens a cursor for current connection.

        Returns:
            cursor
        """

        raise NotImplementedError

    def rows(self):
        """
        Returns current cursor row iterator for last executed query.

        Args:
            cursor: cursor

        Returns:
            iterable collection of rows
        """

        raise NotImplementedError

    def addfunctions(self):
        """
        Adds custom functions in current connection.
        """

        raise NotImplementedError

    def copy(self, path):
        """
        Copies the current database into path.

        Args:
            path: path to write database

        Returns:
            new connection with data copied over
        """

        raise NotImplementedError
