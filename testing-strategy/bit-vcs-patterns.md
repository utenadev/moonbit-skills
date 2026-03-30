# bit-vcs テスト・ビルド戦略

**作成日**: 2026-03-30  
**参照プロジェクト**: [mizchi/bit-vcs](https://github.com/mizchi/bit-vcs)  
**著者**: task_mbt project (Qwen Code)

---

## 概要

bit-vcs は MoonBit で実装された Git 互換 VCS です。97.6% という驚異的なテスト合格率を達成しており、そのテスト戦略とビルド構成は MoonBit プロジェクトのベストプラクティスと言えます。

---

## 1. プロジェクト構造

### 単一ソースディレクトリ

```
bit-vcs/
├── moon.mod.json          # "source": "src"
├── src/                   # 単一ソースディレクトリ
│   ├── cmd/
│   │   ├── bit/           # バイナリ名: bit
│   │   │   ├── main.mbt
│   │   │   ├── add.mbt
│   │   │   └── add_wbtest.mbt
│   │   └── git-bit/       # バイナリ名: git-bit
│   │       └── main.mbt
│   ├── lib/               # サブパッケージ
│   │   ├── branch.mbt
│   │   └── branch_test.mbt
│   ├── pack/              # サブパッケージ
│   │   ├── packfile.mbt
│   │   ├── packfile_test.mbt
│   │   └── packfile_wbtest.mbt
│   └── ...
└── t/                     # Git 公式テストスイート
    ├── run-tests.sh
    ├── t0001-init.sh
    └── ...
```

### moon.mod.json

```json
{
  "name": "mizchi/bit",
  "version": "0.38.0",
  "source": "src",
  "preferred-target": "native",
  "exclude": [
    "t", "e2e", "fixtures", "docs", "tools"
  ]
}
```

**重要な点**:
- ❌ `moon.pkg.json` を各ディレクトリに置かない
- ✅ `moon.mod.json` の `"source": "src"` で管理
- ✅ サブパッケージは自動認識（`mizchi/bit/lib`, `mizchi/bit/pack`）

---

## 2. バイナリ命名規則

### ディレクトリ名 = バイナリ名

```
src/cmd/bit/main.mbt       →  バイナリ：bit
src/cmd/git-bit/main.mbt   →  バイナリ：git-bit
```

### ビルド出力

```bash
moon build --target native --release
```

**出力構造**:
```
_build/native/release/build/
├── cmd/
│   ├── bit/
│   │   └── bit.exe        # ← ディレクトリ名 = バイナリ名
│   └── git-bit/
│       └── git-bit.exe
```

### CI/CD での参照

```yaml
# .github/workflows/release.yml
- name: Build
  run: moon build --target native --release

- name: Prepare artifact
  run: |
    bin_path="_build/native/release/build/cmd/bit/bit.exe"
    cp "$bin_path" bit-linux-x64
```

```just
# justfile
build-native:
    moon build --target native --release
    @bin_path="_build/native/release/build/cmd/bit/bit.exe"; \
    if [ ! -x "$bin_path" ]; then \
      echo "bit binary not found"; \
      exit 1; \
    fi
```

---

## 3. テスト戦略

### 3-1. ユニットテスト（MoonBit ネイティブ）

#### ファイル命名規則

```
src/pack/
├── packfile.mbt           # 実装
├── packfile_test.mbt      # 黒箱テスト
└── packfile_wbtest.mbt    # 白箱テスト
```

#### テスト構文

```moonbit
///|
test "packfile magic and version" {
  let content = Bytes::from_array([b'h', b'e', b'l', b'l', b'o'])
  let packfile = create_blob_packfile(content)

  // Check magic: "PACK"
  inspect(packfile[0], content="b'\\x50'") // 'P'
  inspect(packfile[1], content="b'\\x41'") // 'A'
  inspect(packfile[2], content="b'\\x43'") // 'C'
  inspect(packfile[3], content="b'\\x4B'") // 'K'

  // Check version: 2
  inspect(packfile[4], content="b'\\x00'")
  inspect(packfile[5], content="b'\\x00'")
  inspect(packfile[6], content="b'\\x00'")
  inspect(packfile[7], content="b'\\x02'")
}

///|
test "packfile object count" {
  let content = Bytes::from_array([b'h', b'e', b'l', b'l', b'o'])
  let packfile = create_blob_packfile(content)

  // Check object count: 1
  inspect(packfile[8], content="b'\\x00'")
  inspect(packfile[9], content="b'\\x00'")
  inspect(packfile[10], content="b'\\x00'")
  inspect(packfile[11], content="b'\\x00'")
}
```

#### 実行方法

```bash
# justfile で管理
test:
    moon test --target js -p mizchi/bit -p mizchi/bit/lib
    moon test --target wasm -p mizchi/bit/runtime -f storage_runtime_wbtest.mbt
    moon test --target native --no-parallelize -j 1
    just test-git-compat-allowlist
```

### 3-2. E2E テスト（Git 公式テストスイート）

#### Git 公式テストを流用

```
t/
├── run-tests.sh           # テストランナー
├── t0001-init.sh          # git 公式テスト
├── t0002-basic.sh
├── t0003-plumbing.sh
└── ... (1000+ ケース)
```

#### 成果

```
✅ 成功：24,278 / 24,858
❌ 失敗：0
⚠️ 壊れ：178（意図的）
📊 合格率：97.6%
```

#### テストランナー

```bash
#!/bin/sh
# t/run-tests.sh

for test in t[0-9]*.sh; do
    echo "=== $test ==="
    if ./"$test"; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
        echo "FAILED: $test"
    fi
done

echo "========================================"
echo "Total:  $total"
echo "Passed: $passed"
echo "Failed: $failed"
echo "========================================"
```

---

## 4. なぜテストが機能するのか？

### 理由 1: 単一パッケージ構造

```moonbit
// src/pack/packfile_test.mbt
test "packfile magic" {
  // 同じパッケージ内の関数を直接呼び出し可能
  let packfile = create_blob_packfile(content)
  inspect(packfile[0], content="b'\\x50'")
}
```

**重要な点**:
- ✅ 同じパッケージ内なら `test "desc" { }` が認識される
- ✅ `inspect()` が定義されている
- ✅ `moon test` フレームワークが機能する

### 理由 2: 適切なパッケージ分割

```
src/pack/              # pack パッケージ
├── packfile.mbt       # 実装
└── packfile_test.mbt  # テスト（同じパッケージ）
```

**重要な点**:
- ✅ テストファイルは実装と同じディレクトリ
- ✅ 同じパッケージ名でコンパイルされる
- ✅ 内部関数もテスト可能

### 理由 3: justfile での自動化

```just
test:
    moon test --target native
    just test-git-compat-allowlist

test-update:
    moon test --update --target native
```

---

## 5. 教訓とベストプラクティス

### 5-1. プロジェクト構造

| 項目 | bit-vcs（推奨） | task_mbt（現状） |
|------|-----------------|-----------------|
| ソースディレクトリ | `src/` 単一 | ルート直下 |
| `moon.pkg.json` | なし（`src` のみ） | 各ディレクトリ |
| パッケージ参照 | 自動認識 | 手動インポート |
| クロスパッケージ制限 | 最小限 | 多い |

### 5-2. テスト構文

| 機能 | bit-vcs | task_mbt（現状） |
|------|---------|-----------------|
| `test "desc" { }` | ✅ 動作する | ❌ 認識されない |
| `inspect()` | ✅ 動作する | ❌ 未定義 |
| `moon test` | ✅ 機能する | ⚠️ 実験的 |
| E2E テスト | ✅ git 公式（97.6%） | ✅ go-task（85.8%） |

### 5-3. バイナリ命名

| 項目 | bit-vcs | task_mbt（現状） |
|------|---------|-----------------|
| バイナリ名 | ディレクトリ名で制御 | 不明確 |
| 出力パス | `_build/.../cmd/bit/bit.exe` | `_build/.../cmd/cli/???` |
| CI 参照 | 明確なパス | 要確認 |

---

## 6. task_mbt への適用手順

### ステップ 1: 単一パッケージ構造へ移行

```
task_mbt/
├── moon.mod.json          # "source": "src" を追加
└── src/                   # 新規ディレクトリ
    ├── main.mbt           # task_mbt.mbt から移動
    ├── types.mbt          # 型定義
    ├── logger.mbt         # ロギング
    ├── parser.mbt         # パーサー
    ├── parser_test.mbt    # テスト
    └── cmd/
        └── task/          # バイナリ名: task
            └── main.mbt   # CLI エントリーポイント
```

### ステップ 2: moon.mod.json 更新

```json
{
  "name": "utenadev/task_mbt",
  "version": "0.1.0",
  "source": "src",
  "preferred-target": "native"
}
```

### ステップ 3: テスト構文の再挑戦

```moonbit
// src/parser_test.mbt
test "parse simple Taskfile" {
  let yaml = "version: \"3\"\ntasks:\n  hello:\n    cmd: echo hello"
  
  let result = parse_taskfile(yaml)
  
  match result {
    Ok(_) => println("✅ PASS")
    Err(e) => {
      println("❌ FAIL: " + e)
      panic()
    }
  }
}
```

### ステップ 4: justfile 更新

```just
test:
    moon test --target native
    ./scripts/test-e2e.sh

test-update:
    moon test --update --target native
```

---

## 7. 参考文献

- [bit-vcs Repository](https://github.com/mizchi/bit-vcs)
- [bit-vcs Introduction (Zenn)](https://zenn.dev/mizchi/articles/introduce-bit-by-moonbit)
- [MoonBit Testing Strategy (Native)](./native-testing.md)
- [MoonBit Testing Strategy (WASI)](./wasi-testing.md)
- [go-task E2E Patterns](./go-task-e2e-patterns.md)

---

**End of document**
