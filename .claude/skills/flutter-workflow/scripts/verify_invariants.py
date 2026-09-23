"""Verify the data invariants specified in docs/shared/data/schema.md.

Nothing here is a copy of the specification. Both halves are read from the
docs at run time:
  - the invariant queries (`-- N.` blocks in docs/shared/data/schema.md);
  - the tables they run against, built from the column tables
    (`| Cột | Kiểu | Ghi chú |`) in docs/shared/data/schema.md and
    docs/features/*/data.md.
If someone edits an invariant or a column in the doc and breaks it, this fails.
The fixture below only names columns, so it breaks loudly (not silently) when a
column it uses is renamed.

Two things are checked for every query:
  1. it parses, and returns nothing against a valid 3-level fixture tree;
  2. it actually fires when its own violation is introduced.

Check 2 is the one that matters. A query that never returns rows passes check 1
perfectly while enforcing nothing — that is the failure mode of most hand-written
data checks.

Run:  python3 .claude/skills/flutter-workflow/scripts/verify_invariants.py [--db PATH]
      (from the repository root)
Exit: 0 all good, 1 otherwise.
"""
import argparse
import pathlib
import re
import sqlite3
import sys

SCHEMA_DOC = pathlib.Path("docs/shared/data/schema.md")
TABLE_DOCS = [SCHEMA_DOC, *sorted(pathlib.Path("docs/features").glob("*/data.md"))]

TABLE_HEADING = re.compile(r"^## `(\w+)`\s*$")
COLUMN_HEADER = re.compile(r"^\|\s*Cột\s*\|\s*Kiểu\s*\|")
COLUMN_ROW = re.compile(r"^\|\s*`(\w+)`\s*\|\s*((?:TEXT|INTEGER|REAL|DATETIME)\b[^|]*)\|([^|]*)\|")
FOREIGN_KEY = re.compile(r"→\s*`(\w+)\((\w+)\)`(\s*ON DELETE CASCADE)?")


# ------------------------------------------------------------------ schema


def column_tables(path):
    """Yield (table, [(column, type, note)]) for every documented column table."""
    table, columns, in_columns = None, [], False
    for line in path.read_text(encoding="utf-8").splitlines():
        heading = TABLE_HEADING.match(line)
        if heading or line.startswith("## "):
            if table and columns:
                yield table, columns
            table, columns, in_columns = (heading[1] if heading else None), [], False
            continue
        if table and COLUMN_HEADER.match(line):
            in_columns = True
            continue
        if not in_columns:
            continue
        if not line.startswith("|"):
            in_columns = False
            continue
        row = COLUMN_ROW.match(line)
        if row:
            columns.append((row[1], row[2].strip(), row[3]))
    if table and columns:
        yield table, columns


def column_ddl(name, sql_type, note):
    ddl = f"{name} {sql_type.replace(' PK', ' PRIMARY KEY')}"
    fk = FOREIGN_KEY.search(note)
    if fk:
        ddl += f" REFERENCES {fk[1]}({fk[2]})" + (" ON DELETE CASCADE" if fk[3] else "")
    return ddl


def schema_sql():
    statements = []
    for path in TABLE_DOCS:
        for table, columns in column_tables(path):
            body = ",\n  ".join(column_ddl(*c) for c in columns)
            statements.append(f"CREATE TABLE {table} (\n  {body}\n);")
    return "\n".join(statements)


SCHEMA = schema_sql()


# -------------------------------------------------------------- invariants

doc = SCHEMA_DOC.read_text(encoding="utf-8")
blocks = re.findall(r"```sql\n(.*?)```", doc, re.S)
inv_sql = "\n".join(b for b in blocks if re.search(r"^--\s*\d+\.", b, re.M))
queries = {}
for chunk in re.split(r"\n(?=--\s*\d+\.)", inv_sql):
    m = re.match(r"--\s*(\d+)\.\s*(.+)", chunk)
    if not m:
        continue
    body = "\n".join(l for l in chunk.splitlines() if not l.strip().startswith("--")).strip()
    if body:
        queries[int(m.group(1))] = (m.group(2).strip(), body)

print(f"Trích được {len(queries)} câu invariant từ {SCHEMA_DOC}\n")


# ----------------------------------------------------------------- fixture


def ins(con, table, **values):
    cols = ", ".join(values)
    marks = ", ".join("?" for _ in values)
    con.execute(f"INSERT INTO {table} ({cols}) VALUES ({marks})", tuple(values.values()))


def deck(con, id, parent_id, root_id, depth, content_type, **extra):
    ins(con, "deck", id=id, name=id.upper(), parent_id=parent_id, root_id=root_id,
        depth=depth, content_type=content_type, sibling_position=0,
        created_at="t", updated_at="t", **extra)


def card(con, id, deck_id, **extra):
    ins(con, "card", id=id, deck_id=deck_id, front="f", back="k",
        created_at="t", updated_at="t", **extra)


def schedule(con, card_id, learned_at, due_at):
    ins(con, "card_schedule", card_id=card_id, scheduler_type="eight_box",
        scheduler_version=1, generation=1, learned_at=learned_at, due_at=due_at,
        current_box=1)


def session(con, id, status, end_reason, ended_at, **extra):
    fields = dict(id=id, deck_id="r", root_id="r", generation=1,
                  session_kind="reviewing", current_mode="match", status=status,
                  end_reason=end_reason, card_limit=20, started_at="t",
                  ended_at=ended_at)
    fields.update(extra)
    ins(con, "study_session", **fields)


def answer(con, id, card_id="c1", kind="relearning", mode="match", **extra):
    fields = dict(id=id, card_id=card_id, session_id="s1", scheduler_type="eight_box",
                  generation=1, kind=kind, mode=mode, action="forgotten",
                  answered_at="t", previous_box=1, next_box=1)
    fields.update(extra)
    ins(con, "review_log", **fields)


def queue(con, mode, card_id, position, status="completed", round=1, **extra):
    ins(con, "study_queue_items", session_id="s1", mode=mode, round=round,
        card_id=card_id, position=position, status=status, **extra)


def batch(con, id, item_type, root_item_id, deleted_at):
    ins(con, "delete_batches", id=id, item_type=item_type,
        root_item_id=root_item_id, deleted_at=deleted_at)


def fresh():
    con = sqlite3.connect(":memory:")
    con.executescript(SCHEMA)
    return con


def good(con):
    # Root `r` (eight_box, generation 1) → deck `a` → card deck `b` → card `c1`.
    # `first_answered_at` is set because `c1` carries a `learned_at`: a learned
    # card under an unlocked root is invariant 30's violation (BR-SRS-003), so
    # the fixture that claims to be valid has to be locked.
    deck(con, "r", None, "r", 1, "deck", scheduler_type="eight_box",
         scheduler_version=1, generation=1, first_answered_at="t")
    deck(con, "a", "r", "r", 2, "deck")
    deck(con, "b", "a", "r", 3, "card")
    card(con, "c1", "b")
    schedule(con, "c1", learned_at="t", due_at="t")
    session(con, "s1", "completed", None, "t", cursor=1)
    answer(con, "h1")
    queue(con, "browse", "c1", 0)
    queue(con, "match", "c1", 0, answers_in_session=2)


def chain_below_a(con):
    # Decks x3…x11 hung under `a` (level 2): the deepest is level 11 (BR-DECK-001).
    for n in range(3, 12):
        deck(con, f"x{n}", "a" if n == 3 else f"x{n - 1}", "r", n, "deck")


def too_many_cards(con):
    # 21 distinct cards in a session whose own card_limit is 20 (BR-STUDY-003).
    for n in range(21):
        card(con, f"q{n}", "b")
        queue(con, "match", f"q{n}", n + 10)


# each: query number -> the change that introduces exactly that violation
BAD = {
    1: lambda c: card(c, "cx", "r"),
    2: lambda c: (deck(c, "u", "a", "r", 3, "unset"), card(c, "cu", "u")),
    3: lambda c: deck(c, "z", "b", "r", 4, "deck"),
    4: lambda c: card(c, "ca", "a"),
    5: lambda c: c.execute("UPDATE deck SET content_type = 'card' WHERE id = 'r'"),
    6: lambda c: c.execute("UPDATE deck SET root_id = 'wrong' WHERE id = 'b'"),
    7: lambda c: c.execute("UPDATE deck SET root_id = 'nope' WHERE id = 'r'"),
    8: lambda c: c.execute("UPDATE deck SET parent_id = 'b' WHERE id = 'a'"),
    9: lambda c: c.execute("UPDATE card_schedule SET generation = 99 WHERE card_id = 'c1'"),
    10: lambda c: c.execute("UPDATE deck SET scheduler_type = 'sm2' WHERE id = 'a'"),
    11: lambda c: c.execute("UPDATE deck SET scheduler_type = NULL WHERE id = 'r'"),
    12: lambda c: session(c, "s2", "completed", "user_exit", "t"),
    13: lambda c: session(c, "s3", "abandoned", "user_exit", None),
    14: lambda c: answer(c, "h2", next_box=5),
    15: chain_below_a,
    16: lambda c: (card(c, "c1x", "b"), queue(c, "match", "c1x", 1, status="pending")),
    17: lambda c: (card(c, "c1y", "b"), queue(c, "match", "c1y", 2, available_at=-1)),
    18: too_many_cards,
    19: lambda c: (card(c, "c19", "b"), queue(c, "match", "c19", 0, status="pending", round=3)),
    20: lambda c: (card(c, "c20", "b"), queue(c, "match", "c20", 0, status="pending", round=2)),
    21: lambda c: (card(c, "c21", "b"), queue(c, "match", "c21", 9, status="pending", remaining_ms=500)),
    22: lambda c: answer(c, "h22", kind="scheduled", outcome_reason="timeout"),
    23: lambda c: answer(c, "h23", kind="scheduled", comparison_version=1, used_hint=0),
    24: lambda c: (card(c, "c24", "b"), schedule(c, "c24", learned_at="t", due_at=None)),
    25: lambda c: (card(c, "c25", "b"), schedule(c, "c25", learned_at=None, due_at=None),
                  answer(c, "h25", card_id="c25", kind="scheduled")),
    26: lambda c: answer(c, "h26", kind="learning"),
    27: lambda c: c.execute("UPDATE deck SET study_config = '{}' WHERE id = 'b'"),
    28: lambda c: (card(c, "c28", "b"), schedule(c, "c28", learned_at=None, due_at="t")),
    # `a` is a non-root `deck` whose only child is `b`; drop `b` and `a` is the
    # empty typed deck invariant 29 exists to catch (BR-DECK-015).
    29: lambda c: c.execute("DELETE FROM deck WHERE id = 'b'"),
    30: lambda c: c.execute("UPDATE deck SET first_answered_at = NULL WHERE id = 'r'"),
    # A direction on a queue row of a session that carries none (BR-MODE-015).
    31: lambda c: queue(c, "self_assess", "c1", 5, status="pending", direction="korean_to_meaning"),
    # A turn claiming a direction its own queue row does not have (BR-MODE-016).
    32: lambda c: answer(c, "h32", direction="korean_to_meaning"),
    # ---- Trash (sub-project sau) ----------------------------------------
    # `b` goes to Trash while its card stays active: the state that would make
    # `delete_batch_id IS NULL` stop meaning "visible".
    33: lambda c: (batch(c, "bt1", "deck", "b", "t2"),
                   c.execute("UPDATE deck SET delete_batch_id = 'bt1' WHERE id = 'b'")),
    34: lambda c: (batch(c, "bt2", "deck", "a", "t2"),
                   c.execute("UPDATE deck SET delete_batch_id = 'bt2' WHERE id = 'a'")),
    35: lambda c: batch(c, "bt3", "deck", "r", "t2"),
    # Ancestor deleted BEFORE its descendant — the ordering BR-TRASH-010 leans on.
    36: lambda c: (batch(c, "bt4", "deck", "a", "t1"), batch(c, "bt5", "deck", "b", "t9"),
                   c.execute("UPDATE deck SET delete_batch_id = 'bt4' WHERE id = 'a'"),
                   c.execute("UPDATE deck SET delete_batch_id = 'bt5' WHERE id = 'b'")),
    37: lambda c: batch(c, "bt6", "deck", "nosuchdeck", "t2"),
}


# -------------------------------------------------------------------- main

ap = argparse.ArgumentParser(add_help=True)
ap.add_argument("--db", metavar="PATH",
                help="run the invariants against a real database file instead "
                     "of the built-in fixture")
args = ap.parse_args()

if args.db:
    # Same queries, same source: read out of the document, never hand-copied
    # into the caller.
    db_path = pathlib.Path(args.db)
    if not db_path.exists():
        print(f"✗ không tìm thấy database: {db_path}")
        sys.exit(1)

    con = sqlite3.connect(str(db_path))
    violated = 0
    for n, (label, sql) in sorted(queries.items()):
        try:
            rows = con.execute(sql).fetchall()
        except sqlite3.Error as e:
            print(f"  ✗ Q{n:<2} SQL LỖI: {e}   [{label[:48]}]")
            violated += 1
            continue
        if rows:
            # Ids only. Never a row's content: card text, notes and learning
            # history are private (BR-CORE-001, BR-CORE-002), and a checker's
            # output ends up in logs and CI transcripts.
            ids = ", ".join(str(r[0]) for r in rows[:5])
            print(f"  ✗ Q{n:<2} {label[:56]}  → {len(rows)} dòng: {ids}")
            violated += 1
        else:
            print(f"  ✓ Q{n:<2} {label[:60]}")

    verdict = "SẠCH" if violated == 0 else str(violated) + " VI PHẠM"
    print("")
    print(str(len(queries)) + " invariant chạy trên " + str(db_path) + ": " + verdict)
    sys.exit(1 if violated else 0)

fails = 0
# 1) all queries must parse and return nothing on valid data
c = fresh()
good(c)
for n, (label, sql) in sorted(queries.items()):
    try:
        rows = c.execute(sql).fetchall()
    except sqlite3.Error as e:
        print(f"  ✗ Q{n:<2} SQL LỖI: {e}   [{label[:48]}]")
        fails += 1
        continue
    if rows:
        print(f"  ✗ Q{n:<2} false positive trên dữ liệu hợp lệ: {rows}   [{label[:48]}]")
        fails += 1
print(f"[1] Dữ liệu hợp lệ → {len(queries) - fails} / {len(queries)} câu trả về 0 dòng")

# 2) each query must fire on its own violation
print("\n[2] Mỗi câu phải bắt được vi phạm tương ứng:")
for n, (label, sql) in sorted(queries.items()):
    if n not in BAD:
        print(f"  ✗ Q{n:<2} chưa có case vi phạm")
        fails += 1
        continue
    c = fresh()
    good(c)
    BAD[n](c)
    rows = c.execute(sql).fetchall()
    mark = "✓" if rows else "✗ KHÔNG BẮT ĐƯỢC"
    if not rows:
        fails += 1
    print(f"  {mark} Q{n:<2} {label[:60]}")

print(f"\n{'TẤT CẢ ĐẠT' if fails == 0 else str(fails) + ' LỖI'}")
sys.exit(1 if fails else 0)
