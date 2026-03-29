# Native CLI Testing Strategy

MoonBit の Native backend（LLVM/C バックエンド）で CLI ツールを作成する場合のテスト戦略。

Native ターゲットは**スタンドアロン実行ファイル**（高速・直接 OS API アクセス可能）が出力されるため、ファイル I/O、プロセス制御、環境変数などの CLI らしい振る舞いを**本物のネイティブ環境でテスト**できるのが最大の強みです。

---

## 1. 全体のテストピラミッド（推奨比率）

| レベル | 比率 | 内容 |
|-------|------|------|
| **ユニットテスト（UT）** | 70-80% | 純粋ロジック、パーサー、データ処理、コアアルゴリズム |
| **インテグレーションテスト** | 15-20% | 引数解析 + ロジック + 簡易ファイル I/O |
| **E2E テスト** | 5-10% | 実際のバイナリを実行して、stdout/stderr、exit code、ファイル作成・変更を検証 |

この比率を守ると、メンテナンスしやすく、変更時の安心感が高いです。

---

## 2. ユニットテスト（UT）の戦略

`moon test --target native` で実行可能。デフォルトは debug ビルドなので、スタックトレースも出やすくデバッグしやすいです。

### 基本的な書き方（スナップショット中心）

```moonbit
// src/parser_test.mbt
test "parse complex args" {
  let args = ["mycli", "--verbose", "-o", "output.txt", "input.json"]
  inspect(parse_args(args))  // derive(Show)しておく
}

test "process file content" {
  let input = #|{"items": [1, 2, 3]}|
  let result = process_content(input)?
  @json.inspect(result)  // JSON 出力が見やすい
}
```

### ベストプラクティス

- `inspect(value)` + `moon test -u`（`--update`）でスナップショットを自動更新
- 複雑な出力は `@json.inspect` や `@test.Test` の `snapshot` 機能を使う（任意の文字列/データを記録可能）
- `quickcheck`（`moonbitlang/quickcheck`）でプロパティベーステストを追加（例：「任意の有効引数でパースが panic しない」）
- **純粋関数を増やす**: ファイル I/O や `env::args()` は外側に追い出し、コア部分だけテストしやすくする
- `moon test --target native -j` で並列実行（高速）

### Native 特有の利点

- `async test` が正式に使える（`moonbitlang/async` 依存時）
- LLDB 対応デバッガでテストをステップ実行可能（`moon test` 出力に実行コマンドが表示される）

---

## 3. インテグレーション / E2E テストの戦略

Native CLI では**実際のバイナリを実行**するのが最も信頼性が高いです。

### おすすめ構成

#### 1. テストヘルパー関数を作成（`test/helper.mbt` など）

```moonbit
fn run_cli(args: Array[String]) -> Result[(String, String, Int), String] {
  // 内部でプロセス実行（ただしテスト内では制限ありの場合、自前で spawn）
  // または外部スクリプトに委譲
}
```

#### 2. E2E は外部スクリプト + just/Makefile で自動化（強く推奨）

プロジェクトルートに `justfile` を作成：

```just
# justfile

build-native:
    moon build --target native --release

test-unit:
    moon test --target native

test-e2e:
    ./test/e2e/run_tests.sh

test-all: test-unit test-e2e

run ARGS="":
    moon run --target native main -- {{ARGS}}

clean-test:
    rm -rf tmp/*
```

#### 3. E2E シェルスクリプト例（`test/e2e/run_tests.sh`）

```bash
#!/bin/bash
set -e

BINARY="target/native/release/build/main/main"  # 実際のパスを確認

moon build --target native --release

echo "Testing help output..."
$BINARY --help | grep -q "Usage:" || { echo "Help test failed"; exit 1; }

echo "Testing file processing..."
echo '{"value": 42}' > /tmp/input.json
$BINARY --input /tmp/input.json --output /tmp/output.json
grep -q '"processed": true' /tmp/output.json || { echo "Output check failed"; exit 1; }

echo "Testing error case..."
$BINARY nonexistent.txt && { echo "Should have failed"; exit 1; } || echo "Error case passed"

rm -f /tmp/input.json /tmp/output.json
echo "All E2E tests passed!"
```

#### 4. 高度な E2E（プロセス実行をテスト内で行う）

Native では `@moonbitlang/x/process` や C FFI で `spawn`/`exec` 相当が可能。

```moonbit
// test/e2e/integration_test.mbt  (async test 使用)
///| using moonbitlang/async
///| using moonbitlang/x/fs as fs   // ファイル操作が必要なら

async test "e2e via process spawn" {
  let binary_path = "../target/native/release/build/main/main"

  // プロセス起動例（簡易版）
  let result = @process.spawn(binary_path, ["--help"], ~capture_output=true)?

  assert_true(result.stdout.contains("Usage:"))
  assert_eq(result.exit_code, 0)

  // ファイル作成を伴うテスト
  let input_path = "test_input.json"
  fs::write_string_to_file(input_path, #|{"value": 42}| )?

  let proc = @process.spawn(binary_path, ["--input", input_path, "--output", "out.json"])?

  assert_eq(proc.exit_code, 0)
  let output = fs::read_to_string("out.json")?
  assert_true(output.contains("42"))

  // クリーンアップ
  fs::remove_file(input_path)?
  fs::remove_file("out.json")?
}
```

**注意**:
- `async test` は `--target native` + `moonbitlang/async` 依存時のみ安定
- プロセス実行は `@process` ライブラリ（コミュニティ版も存在）を使うとより便利
- テスト内でビルドを呼ぶと遅くなるので、通常は `just` で事前ビルド

---

## 4. Native 特有の注意点と Tips

| 項目 | 説明 |
|------|------|
| **ファイル I/O** | OS の実際のファイルシステムにアクセスできるので、WASI よりテストが書きやすい。ただしテストは**一時ディレクトリ**（`/tmp` など）を使い、衝突を避ける |
| **プラットフォーム差異** | Linux/macOS/Windows で挙動が変わる可能性がある（パス区切り、改行コードなど）。CI では複数 OS でテスト推奨 |
| **バックトレース** | Native は panic 時に詳細なスタックトレースを出力（0.8.0 以降強化）。デバッグに便利 |
| **カバレッジ** | `moon coverage analyze` で未カバー行をチェック可能 |
| **テスト対象の分離** | `main.mbt` は薄く保ち（引数解析 → コマンド実行のみ）、ロジックは別パッケージに移動してテストしやすくする |
| **CI/CD** | GitHub Actions などで `moon test --target native` + E2E シェルを実行。`just` を導入すると管理しやすい |
| **ドキュメントテスト** | `README.mbt.md` に例を書き、`moon test` で自動検証（サンプルが古くならない） |

---

## 5. 実践的なプロジェクト構成例

```
my-native-cli/
├── src/
│   ├── main.mbt              # エントリポイント（薄く）
│   ├── parser.mbt
│   ├── processor.mbt
│   └── *_test.mbt            # UT 中心
├── test/
│   ├── helper.mbt            # テストユーティリティ
│   └── e2e/
│       └── run_tests.sh      # E2E スクリプト
├── justfile
├── moon.mod.json             # "preferred-target": "native"
└── tmp/                      # テスト用一時ディレクトリ（.gitignore 推奨）
```

### 開発フロー例

1. ロジックを書く → `just test-unit`（高速）
2. CLI 全体変更 → `just test-e2e`
3. 大きなリファクタ → `just test-all`
4. `moon test -u` でスナップショット更新

この戦略で、**Rust の CLI テスト**（golden master + integration test）に近い信頼性を、MoonBit の高速ビルドとスナップショットで実現できます。
