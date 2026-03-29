# Snapshot Testing Guide

MoonBit の**スナップショットテスト**は、`inspect` 関数を中心に非常に使いやすく設計されています。

`moon test --update`（または `-u`）を実行すると、期待値（`content`）を**自動的に挿入・更新**してくれるのが最大の特徴です。これにより、手動で期待値を書く手間が大幅に減り、CLI 開発（出力フォーマット、JSON 処理、パーサー結果など）で特に便利です。

---

## 基本的な使い方

`inspect` 関数のシグネチャ（簡略）:

```moonbit
pub fn inspect(obj: Show, ~content: String = "") -> Unit!
```

- **`obj`**: `Show` トレイトを実装したもの（`derive(Show)` で自動実装可能）。`to_string()` 相当の文字列表現で比較。
- **`~content`**: 期待する文字列（省略可能）。空文字列で始めると `moon test -u` で自動補完。

### シンプル例

```moonbit
test "basic snapshot" {
  inspect(42)                    // content="" で開始可能
  inspect([1, 2, 3])
  inspect({ x: 10, y: 20 })      // struct の場合
}
```

### 初回実行時

```bash
moon test
```

→ 失敗し、差分を表示（実際の出力 vs 空の content）。

### 更新

```bash
moon test -u    # または moon test --update
```

→ 自動で以下のように更新されます：

```moonbit
test "basic snapshot" {
  inspect(42, content="42")
  inspect([1, 2, 3], content="[1, 2, 3]")
  inspect({ x: 10, y: 20 }, content="{x: 10, y: 20}")
}
```

---

## WASI CLI 開発での実践例

WASI CLI（ファイル処理、引数解析、JSON 出力など）でよく使うパターンです。

### 例 1: 引数解析結果のスナップショット

```moonbit
// src/parser.mbt
pub enum Command {
  Help
  Process { input: String, output: Option[String], verbose: Bool }
} derive(Show)

// src/parser_test.mbt
test "parse args" {
  let args1 = ["mycli", "--verbose", "input.txt"]
  inspect(parse_args(args1))   // content="" で開始

  let args2 = ["mycli", "-o", "out.json", "data.txt"]
  inspect(parse_args(args2))
}
```

`moon test -u` 後：

```moonbit
test "parse args" {
  inspect(parse_args(args1), content="Process { input: \"input.txt\", output: None, verbose: true }")
  inspect(parse_args(args2), content="Process { input: \"data.txt\", output: Some(\"out.json\"), verbose: false }")
}
```

### 例 2: ファイル処理・JSON 出力のスナップショット

```moonbit
// src/processor.mbt
pub fn process_json(content: String) -> Result[JsonValue, Error] { ... }

test "process json file" {
  let input = #|{"name": "test", "value": 42}|
  let result = process_json(input)?
  inspect(result)   // 複雑な構造は @json.inspect がおすすめ
}
```

### より読みやすい JSON スナップショット（`@json.inspect` 推奨）

```moonbit
test "json output" {
  let data = process_data()
  @json.inspect(data, content= #|{
    "processed": true,
    "items": [1, 2, 3],
    "metadata": { "version": "1.0" }
  }|)
}
```

`@json.inspect` は JSON 形式で出力されるため、構造が複雑な場合（AST、CLI の出力オブジェクトなど）に特に見やすいです。

### 例 3: CLI 全体の出力検証（E2E 寄り）

```moonbit
test "cli help output" {
  // ヘルプ文字列生成関数（純粋関数にしておく）
  let help_text = generate_help()
  inspect(help_text, ~content= #|
    Usage: mycli [OPTIONS] <FILE>
    
    Options:
      -v, --verbose    Enable verbose mode
      -o, --output     Output file path
  |)
}
```

マルチラインは `#|` raw string literal が便利です。

---

## ベストプラクティス（WASI CLI 向け）

### 1. 書き方の流れ

1. 新規テスト時は `inspect(value)` または `inspect(value, content="")` で書く
2. `moon test` で実行 → 差分を確認
3. 正しければ `moon test -u` で更新
4. 変更があったら差分を見て意図的か確認 → 必要なら更新

### 2. Show トレイト

- `struct` / `enum` には `derive(Show)` を付ける
- 複雑な型は `@json.inspect` を併用（より構造的に検証可能）

### 3. WASI/Component Model 特有の Tips

- **純粋関数をテスト**: `env::args()` や `fs::read` などの副作用は外側に置き、コアロジック（パーサー、プロセッサ）を `inspect` で検証
- **出力フォーマット**: CLI の stdout 相当の文字列を関数化してスナップショット化（カラフル出力は ANSI コードを考慮）
- **エラーケース**: `Result` の `Err` も `Show` で検証
- E2E では wasmtime 実行結果を shell で比較しつつ、内部ロジックは `inspect` でカバー

### 4. 更新時の注意

- `moon test -u` は**現在のテスト結果**で `content` を上書きするので、意図しない変更がないか確認
- CI では `-u` なしで実行（スナップショットが一致するかだけチェック）
- 大きな変更時はスナップショットをレビュー（git diff で差分が見やすい）

### 5. 組み合わせ

- `assert_eq` + `inspect`: シンプルな値は `assert_eq`、複雑構造は `inspect`
- `quickcheck` と併用：ランダム入力で生成した値を `inspect` で検証

---

## 実行コマンドまとめ

| コマンド | 説明 |
|---------|------|
| `moon test` | テスト実行（失敗時に差分表示） |
| `moon test -u` / `--update` | スナップショット更新 |
| `moon test --target wasm-gc` | WASI ターゲットでテスト |
| `moon test file_test.mbt` | 特定ファイルのみ |

---

## まとめ

この仕組みは、**Rust の insta**や**Jest の toMatchSnapshot**に似ていますが、言語組み込みで更新がよりシームレスです。

WASI CLI の開発では、引数解析結果・加工後データ・最終出力文字列などを積極的に `inspect`/`@json.inspect` でカバーすると、リファクタ時の安心感が格段に上がります。
