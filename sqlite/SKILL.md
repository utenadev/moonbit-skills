# SQLite Integration Guide

MoonBit での SQLite 連携ガイド。`moonbit-community/sqlite3` パッケージを使用。

## インストール

```bash
moon add moonbit-community/sqlite3
```

`moon.pkg.json` にインポートを追加：

```json
{
  "import": [
    "moonbit-community/sqlite3" @sqlite3
  ]
}
```

## 基本操作

### データベース接続

```moonbit
// 接続を開く
let conn = try @sqlite3.Connection::open(db_path) catch {
  _ => return Result::Err("Failed to open database")
}

// 接続を閉じる
storage.conn.close()
```

### テーブル作成

```moonbit
let stmt = try conn.prepare("CREATE TABLE IF NOT EXISTS config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);") catch { _ => return Result::Err("prepare failed") }

try stmt.step_once() catch { _ => () }
try stmt.finalize() catch { _ => () }
```

## CRUD 操作

### INSERT

```moonbit
let stmt = try storage.conn.prepare("INSERT INTO issues (id, title, status) VALUES (?, ?, ?);") catch { _ => return Result::Err("prepare failed") }

try stmt.bind(index=1, id) catch { _ => return Result::Err("bind failed") }
try stmt.bind(index=2, title) catch { _ => return Result::Err("bind failed") }
try stmt.bind(index=3, status) catch { _ => return Result::Err("bind failed") }

try stmt.step_once() catch { _ => return Result::Err("step failed") }
try stmt.finalize() catch { _ => return Result::Err("finalize failed") }

Result::Ok(())
```

### SELECT

```moonbit
let stmt = try storage.conn.prepare("SELECT id, title, status FROM issues WHERE id = ?;") catch { _ => return Result::Err("prepare failed") }

try stmt.bind(index=1, id) catch { _ => return Result::Err("bind failed") }

let result = if try stmt.step() catch { _ => return Result::Err("step failed") } {
  let issue_id : String = stmt.column(index=0)
  let title : String = stmt.column(index=1)
  let status : String = stmt.column(index=2)
  
  try stmt.finalize() catch { _ => return Result::Err("finalize failed") }
  
  Result::Ok(Option::Some(issue))
} else {
  try stmt.finalize() catch { _ => return Result::Err("finalize failed") }
  Result::Ok(Option::None)
}
```

### UPDATE

```moonbit
let stmt = try storage.conn.prepare("UPDATE issues SET status = ?, updated_at = strftime('%s', 'now') WHERE id = ?;") catch { _ => return Result::Err("prepare failed") }

try stmt.bind(index=1, status) catch { _ => return Result::Err("bind failed") }
try stmt.bind(index=2, id) catch { _ => return Result::Err("bind failed") }

try stmt.step_once() catch { _ => return Result::Err("step failed") }
try stmt.finalize() catch { _ => return Result::Err("finalize failed") }

Result::Ok(())
```

### DELETE

```moonbit
let stmt = try storage.conn.prepare("DELETE FROM issue_dependencies WHERE issue_id = ? AND depends_on = ?;") catch { _ => return Result::Err("prepare failed") }

try stmt.bind(index=1, issue) catch { _ => return Result::Err("bind failed") }
try stmt.bind(index=2, depends_on) catch { _ => return Result::Err("bind failed") }

try stmt.step_once() catch { _ => return Result::Err("step failed") }
try stmt.finalize() catch { _ => return Result::Err("finalize failed") }

Result::Ok(())
```

## エラー処理パターン

### try/catch/noraise

```moonbit
let stmt = try storage.conn.prepare("SELECT ...") catch {
  _ => return Result::Err("prepare failed")
}
noraise { s => s }
```

### match パターン

```moonbit
let result = match get_dependencies(storage, issue) {
  Result::Ok(d) => d
  Result::Err(e) => return Result::Err(e)
}
```

## NULL 値の扱い

MoonBit の SQLite バインディングでは `Option::None` が使えないため、空文字列で代用：

```moonbit
match issue.description {
  Option::Some(desc) => {
    try stmt.bind(index=6, desc) catch { ... }
  }
  Option::None => {
    try stmt.bind(index=6, "") catch { ... }
  }
}
```

## トランザクション

```moonbit
try storage.conn.execute("BEGIN TRANSACTION;") catch { ... }

// 複数の操作を実行

try storage.conn.execute("COMMIT;") catch { ... }
// または
try storage.conn.execute("ROLLBACK;") catch { ... }
```

## インデックス作成

```moonbit
let stmt = try conn.prepare("CREATE INDEX IF NOT EXISTS idx_issues_status ON issues(status);") catch { _ => return Result::Err("prepare failed") }

try stmt.step_once() catch { _ => () }
try stmt.finalize() catch { _ => () }
```

## 参考

- [sqlite3.mbt](https://github.com/myfreess/sqlite3.mbt) - MoonBit SQLite バインディング
- [beads_mbt/lib/storage.mbt](https://github.com/utenadev/beads_mbt/blob/main/lib/storage.mbt) - 実装例
