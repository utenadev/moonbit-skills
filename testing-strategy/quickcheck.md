# QuickCheck Guide

MoonBit の**QuickCheck**（`moonbitlang/quickcheck`）は、**Property-Based Testing (PBT)** を実現するライブラリです。

手書きのユニットテスト（例：特定の入力で assert）ではなく、「**任意の有効な入力に対して常に成り立つ性質（Property）**」を定義し、ランダムに大量のテストデータを生成して検証します。失敗した場合は**自動で最小の反例（counterexample）に shrink（縮小）**してくれるのが強力な点です。

Native CLI 開発でも非常に有効で、特に**パーサー、データ処理、アルゴリズム**の堅牢性を高められます。

---

## 1. インストールと設定

```bash
moon add moonbitlang/quickcheck
moon install
```

`moon.pkg.json` にエイリアスを追加（おすすめ）：

```json
{
  "import": [
    "moonbitlang/quickcheck as qc"
  ]
}
```

---

## 2. 基本的な使い方

QuickCheck の主な書き方は以下の 2 パターンです：

- **`@qc.quick_check_fn(fn)`**: シンプルなプロパティ関数を直接テスト
- **`@qc.quick_check( ... )`**: オプション（回数、shrink 制限、expect=Fail など）を指定

### 例：リスト反転の恒等性（reverse(reverse(xs)) == xs）

```moonbit
// src/list_utils.mbt
pub fn reverse[T](xs: Array[T]) -> Array[T] { ... }

// src/list_utils_test.mbt
fn prop_reverse_identity[T: Show + Eq](xs: Array[T]) -> Bool {
  reverse(reverse(xs)) == xs
}

test "reverse is involution" {
  @qc.quick_check_fn(prop_reverse_identity)  // デフォルトで 100 回程度ランダムテスト
}
```

これを実行すると：

- `moon test --target native`
- OK なら「passed N tests」と表示
- 失敗したら**最小の反例**（例：`[1, 0]`）と shrink 過程を表示

---

## 3. より実践的な CLI 向け例（Native CLI でよく使うパターン）

### 例 1: 引数パーサーの性質（任意の文字列配列でパースがパニックしない）

```moonbit
fn prop_parser_never_crashes(args: Array[String]) -> Bool {
  match parse_args(args) {  // あなたの CLI パーサー関数
    Ok(_) | Err(_) => true   // Result なら常に成功（パニックしなければ OK）
  }
}

test "parser never panics on arbitrary input" {
  @qc.quick_check_fn(prop_parser_never_crashes, max_tests=500)
}
```

### 例 2: JSON 処理の往復性（encode → decode == 元のデータ）

```moonbit
fn prop_json_roundtrip(data: JsonValue) -> Bool {  // JsonValue は Show + Eq が必要
  match encode_json(data) {
    Ok(encoded) => decode_json(encoded) == Ok(data)
    Err(_) => false
  }
}

test "json roundtrip" {
  @qc.quick_check(
    @qc.Arrow(prop_json_roundtrip),  // Arrow で関数をラップする場合も
    max_tests=200,
    max_size=50                      // 生成するデータの複雑さ上限
  )
}
```

### 例 3: 失敗を期待するテスト（バグ再現や不変条件違反）

```moonbit
test "sort should maintain length" {
  @qc.quick_check_fn(prop_length_is_not_greater, expect=Fail)  // 意図的に失敗させるテスト
}
```

---

## 4. よく使うオプションと機能

| オプション | 説明 |
|-----------|------|
| `max_tests` | テスト回数（デフォルト 100 前後、CLI では 200〜1000 くらいが現実的） |
| `max_size` | 生成データのサイズ上限（Array の長さなど） |
| `max_shrink` | shrink 試行回数の上限 |
| `expect=Fail` | このプロパティは失敗することを期待（リグレッションテストに便利） |
| `label`, `classify`, `collect` | テストデータを分類・統計表示（デバッグ用） |

### Shrink（縮小）

失敗した入力に対して、QuickCheck が自動で「より小さい入力」に変えながら再テストし、最小の反例を探します。これが PBT の最大の価値の一つです。

---

## 5. Native CLI 開発でのおすすめ戦略

| テストレベル | ツール | 用途 |
|------------|-------|------|
| **ユニットテスト** | `inspect` + `assert_eq` | シンプルなケースや境界値 |
| **QuickCheck** | `@qc.quick_check_fn` | ランダム性が必要な部分（パーサー、ソート、フィルタ、変換ロジック） |
| **E2E** | `just test-e2e` | 実際のバイナリ実行 |

### Tips

- テスト対象の型に `Show` と `Eq`（または `Testable`）を実装（`derive(Show, Eq)` が便利）
- 複雑な入力が必要ならカスタム `Gen[T]` を作成可能（`@qc.Gen`）
- Native ターゲットで実行：`moon test --target native`
- 失敗したら出力される counterexample をコピーして、再現テストを書く習慣をつける

---

## 6. 実行コマンド例

```bash
moon test --target native                     # 通常実行
moon test --target native list_utils_test.mbt # 特定ファイル
moon test -u                                  # スナップショット更新（inspect と併用可）
```

---

## まとめ

QuickCheck は特に**「見落としやすいエッジケース」**を発見しやすいので、Native CLI の引数解析やファイル処理ロジックに積極的に導入すると良いです。

あなたの CLI で QuickCheck を適用したい具体的な部分（例：引数パーサー、JSON/CSV 処理、ファイルフィルタリング、ソート機能など）があれば、よりピンポイントなプロパティ例を作成できます。
