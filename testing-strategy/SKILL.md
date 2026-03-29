# MoonBit Testing Strategy Guide

MoonBit でのテスト戦略ガイド。WASM CLI、Native CLI、QuickCheck を網羅。

## 目次

- [WASI CLI のテスト戦略](./wasi-testing.md)
- [Native CLI のテスト戦略](./native-testing.md)
- [スナップショットテスト詳細](./snapshot.md)
- [QuickCheck 使い方](./quickcheck.md)

---

## 1. MoonBit テスト基盤の概要

MoonBit は組み込みで強力なテスト機能を備えています。

### テストの書き方

- **テストブロック**: `test "名前" { ... }`（任意の名前）
- **アサーション**:
  - `assert_eq(a, b)`
  - `assert_true(condition)`
  - `inspect(value, ~content=...)` - **スナップショットテスト**
- **スナップショット更新**: `moon test --update`（または `-u`）で自動更新
- **エラー処理**: `?`（Result/Error 処理）もテスト内で自然に使える

### 実行コマンド

| コマンド | 説明 |
|---------|------|
| `moon test` | プロジェクト全体のテスト実行（デフォルト debug モード） |
| `moon test --target wasm-gc` / `native` / `js` / `all` | ターゲット指定 |
| `moon test file.mbt` | 単一ファイル指定 |
| `moon test -u` | スナップショット更新 |
| `moon test --outline` | テスト一覧表示 |
| `moon test -j N` | 並列実行 |

### テストファイルの置き方

| ファイル | 用途 |
|---------|------|
| `*_test.mbt` | ホワイトボックステスト（同じパッケージ内） |
| `*_wbtest.mbt` | ホワイトボックステスト |
| `blackbox_test.mbt` | 外部公開 API のみテスト |
| `*.mbt.md` | Markdown ドキュメント内テスト |

### 追加ツール

- **`moonbitlang/quickcheck`** - Property-based / ランダムテスト
- **カスタムアサーション** - 自前で `expect` スタイルも簡単に作成可能

---

## 2. テストピラミッド（推奨比率）

| レベル | 比率 | 内容 |
|-------|------|------|
| **ユニットテスト** | 70-80% | 純粋ロジック、パーサー、プロセッサ |
| **インテグレーションテスト** | 15-20% | 引数解析 + ロジック + 簡易出力検証 |
| **E2E テスト** | 5-10% | 実際の CLI 実行 |

### 開発フロー

1. ロジックを書く → `moon test` で UT（`inspect` 多用）
2. `moon test -u` でスナップショット更新
3. QuickCheck でエッジケースを発見
4. E2E スクリプトを追加・実行
5. リファクタ時は UT がガード、E2E で全体確認

この戦略で、**Rust の CLI テスト**（unit + integration + golden file テスト）に近い堅牢性を、MoonBit の高速コンパイル・組み込みスナップショットで実現できます。
