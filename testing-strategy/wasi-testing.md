# WASI CLI Testing Strategy

WASI CLI（特に wasm-gc + Component Model）を開発する場合の、ユニットテスト（UT）と E2E テストの戦略。

## ユニットテスト（UT）の戦略

**コアロジック中心**に書くのが基本です。WASI 依存を最小限に抑えて、純粋関数やビジネスロジックを徹底的にテストします。

### おすすめの書き方例

```moonbit
// src/parser_test.mbt
test "parse simple args" {
  let args = ["prog", "--verbose", "input.txt"]
  let cmd = parse_args(args)  // 純粋関数
  assert_eq(cmd.verbose, true)
  assert_eq(cmd.input, Some("input.txt"))
}

test "json processing" {
  let input = #|{"name": "test", "value": 42}|
  let result = process_json(input)?
  inspect(result, ~content=#|{ "processed": true, "value": 42 }|)  // スナップショット
}
```

### ベストプラクティス

- **純粋関数を多用**: `fn process(data: String) -> Result[T, E]` のように副作用を分離 → テストが書きやすい
- **スナップショット多用**: JSON 出力、テーブル形式出力、複雑な構造体などで特に有効
- **Property-based Testing**: `quickcheck` で「任意の有効な引数でパースがクラッシュしない」などを検証
- **カバレッジ**: `moon test` と組み合わせてカバレッジ計測（将来的により強化予定）
- 小さなパッケージごとにテストを書く（MoonBit のモジュールシステムと相性良い）

---

## E2E テストの戦略（WASI CLI 特有）

WASI/Component Model の場合、**本物の Wasm 実行環境で CLI 全体をテスト**するのが最も効果的です。

### 推奨アプローチ

#### 1. wasmtime を使った E2E テスト（最も実用的）

`just` や Makefile / shell スクリプトで自動化します。

**例：test/e2e/test_cli.sh**

```bash
#!/bin/bash
# test/e2e/test_cli.sh

BUILD="target/wasm-gc/release/build/mycli/main.component.wasm"

moon build --target wasm-gc --release

# Component 化（必要なら）
wasm-tools component embed wit/ $BUILD -o temp.wasm
wasm-tools component new temp.wasm -o $BUILD

# E2E テスト実行例
run_test() {
  local input="$1"
  local expected="$2"
  local output=$(wasmtime run --dir=. $BUILD -- $input 2>&1)
  if [[ "$output" == *"$expected"* ]]; then
    echo "✓ $input"
  else
    echo "✗ $input (got: $output)"
    exit 1
  fi
}

run_test "input.txt" "Processed successfully"
run_test "--help" "Usage:"
run_test "badfile" "Error: file not found"
```

#### 2. MoonBit 内で E2E 寄りテストを書く場合

- `wasi:cli/run` や `wasi:filesystem` のモック/テスト用ホストを実装
- ただし複雑になるので、シンプル CLI では**wasmtime 呼び出し**の方が現実的

#### 3. Integration Test（中間層）

- 引数解析 → ロジック → 出力 の流れを 1 つのテストで検証
- `env::args()` や `fs` bindings を注入できるように設計（Dependency Injection 風）

---

## 全体のテスト戦略（テストピラミッド）

| レベル | 比率 | 内容 |
|-------|------|------|
| **ユニットテスト** | 70-80% | 純粋ロジック、パーサー、プロセッサ |
| **インテグレーションテスト** | 15-20% | 引数解析 + コアロジック + 簡易出力検証 |
| **E2E テスト** | 5-10% | wasmtime で実際の CLI 実行、ファイル I/O、exit code 検証 |

---

## WASI/Component Model 特有の Tips

- **Preopen（`--dir=.`）** をテストスクリプトで必ず指定
- **Component 化後のテスト**: `wasm-tools component new` した `.component.wasm` に対して実行
- **エラーケース重視**: sandbox 制限によるファイルアクセスエラー、引数エラー、ストリーム EOF などを網羅
- **並列テスト**: `moon test -j` で高速化（E2E は直列推奨）
- **CI/CD**: GitHub Actions などで `wasmtime` をインストールして `just test` 実行

---

## 実践的なおすすめ構成例

```
my-wasm-cli/
├── src/
│   ├── main.mbt          # CLI エントリ（薄く保つ）
│   ├── parser.mbt
│   ├── processor.mbt
│   └── parser_test.mbt   # UT
├── test/
│   ├── e2e/
│   │   └── cli_test.sh   # wasmtime で E2E
│   └── integration_test.mbt
├── wit/
│   └── world.wit         # Component 定義
├── justfile              # just run / test / e2e
└── moon.mod.json
```

### justfile 例

```just
test:
    moon test --target wasm-gc

e2e:
    ./test/e2e/cli_test.sh

all: test e2e
```

---

## まとめとアドバイス

- **UT** → `moon test` + `inspect` + `quickcheck` で高速・高カバレッジを目指す
- **E2E** → `wasmtime run` で実際の CLI を叩く（一番信頼性が高い）
- **開発フロー**: まずは純粋ロジックを UT で固め → E2E で全体を検証
- Component Model を使う場合、WIT 定義が変わってもテストが壊れにくいよう、インターフェースを明確に分離する

この戦略で、Rust CLI 並みの堅牢性を持ちつつ、MoonBit の高速コンパイル・スナップショットテストの恩恵を最大限受けられます。
