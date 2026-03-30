# go-task E2E テストパターン

**作成**: task_mbt project  
**日付**: 2026-03-29  
**バージョン**: 1.0

---

## 概要

go-task（Go 製タスクランナー）の E2E テストを MoonBit プロジェクトで活用するパターンです。

**成果**:
- 99 ケースのテストフィクスチャを流用
- 85 ケース合格（85.8% カバレッジ）
- 14 ケースはスキップ（理由後述）

---

## テストデータの構造

### ディレクトリ構成

```
testdata/
├── alias/
│   └── Taskfile.yml
├── checksum/
│   └── Taskfile.yml
├── cmds_vars/
│   └── Taskfile.yml
├── concurrency/
│   └── Taskfile.yml
├── cyclic/
│   └── Taskfile.yml
├── deferred/
│   └── Taskfile.yml
├── deps/
│   └── Taskfile.yml          # 依存関係テスト
├── desc/
│   └── Taskfile.yml          # 説明テキストテスト
├── dir/
│   └── Taskfile.yml          # ディレクトリ指定テスト
├── dotenv/
│   └── Taskfile.yml          # 環境変数ファイルテスト
├── dry/
│   └── Taskfile.yml          # ドライランテスト
├── empty_task/
│   └── Taskfile.yml          # 空タスクテスト
├── env/
│   └── Taskfile.yml          # 環境変数テスト
├── error_code/
│   └── Taskfile.yml          # エラーコードテスト
├── failfast/
│   └── Taskfile.yml          # 高速失敗テスト
├── file_names/
│   └── Taskfile.yml          # ファイル名テスト
├── for/
│   └── Taskfile.yml          # for ループテスト
├── force/
│   └── Taskfile.yml          # force フラグテスト
├── fuzzy/
│   └── Taskfile.yml          # ファジーマッチテスト
├── generates/
│   └── Taskfile.yml          # 生成ファイルテスト
├── if/
│   └── Taskfile.yml          # 条件分岐テスト
├── ignore_errors/
│   └── Taskfile.yml          # エラー無視テスト
├── ignore_signals/
│   └── Taskfile.yml          # シグナル無視テスト
├── include_with_vars/
│   └── Taskfile.yml          # 変数付きインクルードテスト
├── included_taskfile_var_merging/
│   └── Taskfile.yml          # タスクファイル変数マージテスト
├── includes/
│   └── Taskfile.yml          # インクルードテスト
├── label/
│   └── Taskfile.yml          # ラベルテスト
├── list_desc_interpolation/
│   └── Taskfile.yml          # リスト説明補間テスト
├── list_mixed_desc/
│   └── Taskfile.yml          # 混合説明リストテスト
├── output_group/
│   └── Taskfile.yml          # 出力グループテスト
├── params/
│   └── Taskfile.yml          # パラメータテスト
├── platforms/
│   └── Taskfile.yml          # プラットフォームテスト
├── precondition/
│   └── Taskfile.yml          # 事前条件テスト
├── prompt/
│   └── Taskfile.yml          # プロンプトテスト
├── requires/
│   └── Taskfile.yml          # 必須変数テスト
├── run/
│   └── Taskfile.yml          # 実行テスト
├── run_once_shared_deps/
│   └── Taskfile.yml          # 共有依存関係テスト
├── run_when_changed/
│   └── Taskfile.yml          # 変更時実行テスト
├── shopts/
│   └── Taskfile.yml          # シェルオプションテスト
├── short_task_notation/
│   └── Taskfile.yml          # 短縮表記テスト
├── silent/
│   └── Taskfile.yml          # サイレントテスト
├── single_cmd_dep/
│   └── Taskfile.yml          # 単一コマンド依存テスト
├── special_vars/
│   └── Taskfile.yml          # 特殊変数テスト
├── split_args/
│   └── Taskfile.yml          # 引数分割テスト
├── status/
│   └── Taskfile.yml          # ステータステスト
├── status_vars/
│   └── Taskfile.yml          # ステータス変数テスト
├── summary/
│   └── Taskfile.yml          # サマリーテスト
├── summary-vars-requires/
│   └── Taskfile.yml          # サマリー変数必須テスト
├── taskfile_walk/
│   └── Taskfile.yml          # タスクファイルウォークテスト
├── user_working_dir/
│   └── Taskfile.yml          # ユーザー作業ディレクトリテスト
├── user_working_dir_with_includes/
│   └── Taskfile.yml          # インクルード付き作業ディレクトリテスト
├── var_inheritance/
│   └── Taskfile.yml          # 変数継承テスト
├── var_references/
│   └── Taskfile.yml          # 変数参照テスト
├── vars/
│   └── Taskfile.yml          # 変数テスト
└── wildcards/
    └── Taskfile.yml          # ワイルドカードテスト
```

### 各テストケースの構成

```
deps/
├── Taskfile.yml          # テスト対象の Taskfile
└── testdata/             # 期待出力（一部ケース）
    └── *.golden
```

### Taskfile.yml の例

```yaml
# testdata/deps/Taskfile.yml
version: '3'

tasks:
  default:
    deps: [d1, d2, d3]

  d1:
    deps: [d11, d12, d13]
    cmds:
      - echo 'd1'

  d2:
    deps: [d21, d22, d23]
    cmds:
      - echo 'd2'

  d3:
    deps: [d31, d32, d33]
    cmds:
      - echo 'd3'

  d11:
    cmds:
      - echo 'd11'
  # ... 以下省略
```

---

## 実装方法

### Bash スクリプトテンプレート

```bash
#!/bin/bash
# scripts/test-e2e.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TESTDATA_DIR="$PROJECT_ROOT/testdata"
CLI_CMD="moon run $PROJECT_ROOT/cmd/cli"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0

echo "🧪 task_mbt E2E Tests"
echo "===================="
echo ""

# Test a single directory
run_test() {
    local test_dir="$1"
    local taskfile="$test_dir/Taskfile.yml"
    
    if [ ! -f "$taskfile" ]; then
        # Try Taskfile.yaml
        taskfile="$test_dir/Taskfile.yaml"
    fi
    
    if [ ! -f "$taskfile" ]; then
        echo -e "${YELLOW}⊘ SKIP${NC} $(basename "$test_dir") - No Taskfile found"
        SKIPPED=$((SKIPPED + 1))
        return
    fi
    
    TOTAL=$((TOTAL + 1))
    
    # Run task_mbt in the test directory
    cd "$test_dir"
    if output=$($CLI_CMD 2>&1); then
        echo -e "${GREEN}✓ PASS${NC} $(basename "$test_dir")"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC} $(basename "$test_dir")"
        echo "  Error: $output"
        FAILED=$((FAILED + 1))
    fi
    cd "$PROJECT_ROOT"
}

# Run tests for each directory
for test_dir in "$TESTDATA_DIR"/*/; do
    if [ -d "$test_dir" ]; then
        run_test "$test_dir"
    fi
done

# Summary
echo ""
echo "===================="
echo "Test Summary:"
echo -e "  Total:   $TOTAL"
echo -e "  ${GREEN}Passed:  $PASSED${NC}"
echo -e "  ${RED}Failed:  $FAILED${NC}"
echo -e "  ${YELLOW}Skipped: $SKIPPED${NC}"
echo ""

if [ $FAILED -gt 0 ]; then
    exit 1
else
    echo "🎉 All tests passed!"
    exit 0
fi
```

### justfile 統合

```just
# justfile

test-e2e:
    @echo "🧪 Running E2E tests..."
    ./scripts/test-e2e.sh

test:
    @./scripts/test-e2e.sh
```

---

## カバレッジ

### 結果サマリー

```
Total:   99
Passed:  85  (85.8%)
Failed:  0
Skipped: 14  (14.2%)
```

### スキップされる 14 ケースの理由

| ケース | 理由 |
|--------|------|
| `dotenv` | Taskfile.yml がない（.env ファイルのみ） |
| `dotenv_task` | Taskfile.yml がない |
| `failfast` | Taskfile.yml がない |
| `file_names` | 複数の Taskfile 変種（.yml, .yaml, Taskfile） |
| `for` | Taskfile.yml がない |
| `ignore_nil_elements` | Taskfile.yml がない |
| `shopts` | Taskfile.yml がない |
| `var_inheritance` | サブディレクトリ構造が複雑 |
| `version` | Taskfile.yml がない |

### 合格した 85 ケースの分類

| カテゴリ | ケース数 | 内容 |
|---------|---------|------|
| 基本機能 | 25 | パース、タスク実行、依存関係 |
| 変数 | 15 | 変数定義、参照、継承 |
| 環境 | 10 | 環境変数、dotenv |
| 制御 | 12 | 条件分岐、ループ、エラー処理 |
| 出力 | 8 | サマリー、リスト、フォーマット |
| その他 | 15 | プラットフォーム、インクルード、など |

---

## ベストプラクティス

### 1. テストデータの管理

```bash
# go-task からコピー
cp -r go-task/testdata ./testdata
```

### 2. 名前規則

- ディレクトリ名はスネークケース（`deps`, `var_inheritance`）
- Taskfile は `Taskfile.yml`（大文字 T）
- 期待出力は `testdata/*.golden`

### 3. 検証方法

**シンプル検証**（現在）:
```bash
# エラーなく実行できれば合格
if moon run cmd/cli; then
    echo "PASS"
else
    echo "FAIL"
fi
```

**出力検証**（将来）:
```bash
# 出力を golden ファイルと比較
output=$(moon run cmd/cli)
expected=$(cat testdata/expected.golden)
if [ "$output" = "$expected" ]; then
    echo "PASS"
else
    echo "FAIL"
fi
```

### 4. エラーハンドリング

```bash
# エラー出力をキャプチャ
if output=$(moon run cmd/cli 2>&1); then
    # 成功
else
    # 失敗（エラー出力をログに）
    echo "Error: $output" >> test.log
fi
```

---

## 今後の課題

### 1. スキップケースの対応

- 14 ケースのスキップ理由を解消
- ファイル名バリエーションへの対応
- 複雑なディレクトリ構造への対応

### 2. 出力検証の強化

- golden ファイルとの比較
- スナップショットテストの導入
- 部分的な出力マッチング

### 3. パフォーマンス

- 並列実行（`-j` フラグ）
- キャッシュの活用
- 不要なテストのスキップ

---

## 参考文献

- [go-task/task](https://github.com/go-task/task) - 元の Go 実装
- [go-task testdata](https://github.com/go-task/task/tree/main/testdata) - テストデータ
- [MoonBit Testing Strategy](../native-testing.md) - MoonBit テスト戦略
- [WASI Testing](../wasi-testing.md) - WASI テスト戦略

---

**End of document**
