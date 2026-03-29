# beads_mbt Project Skills

beads_mbt プロジェクト固有の開発スキル。

## プロジェクト概要

beads_mbt は、Rust で実装された [beads_rust](https://github.com/Dicklesworthstone/beads_rust) を MoonBit に移植したプロジェクトです。

- **目的**: Git リポジトリ向けのローカルファーストなイシュートラッカー
- **リポジトリ**: https://github.com/utenadev/beads_mbt
- **ターゲット**: Native（JS/WASM も可能）

## 実装済み機能

| コマンド | 機能 | 状態 |
|---------|------|------|
| `init` | SQLite DB 初期化 | ✅ |
| `create` | Issue 作成 | ✅ |
| `list` | Issue 一覧表示 | ✅ |
| `show` | Issue 詳細表示 | ✅ |
| `update` | Issue 更新 | ✅ |
| `close` | Issue 完了 | ✅ |
| `ready` | 着手可能 Issue | ✅ |
| `defer` | Issue 延期 | ✅ |
| `dep` | 依存関係管理 | ✅ |
| `label` | ラベル管理 | ✅ |
| `search` | 全文検索 | ✅ |
| `comments` | コメント機能 | ✅ |
| `blocked` | ブロック Issue 一覧 | ✅ |

## プロジェクト構造

```
beads_mbt/
├── cmd/main/
│   ├── main.mbt          # CLI エントリーポイント
│   └── moon.pkg
├── lib/
│   ├── model.mbt         # データモデル
│   ├── storage.mbt       # SQLite ストレージ
│   ├── util.mbt          # ユーティリティ
│   └── moon.pkg.json
├── scripts/
│   └── e2e_test.sh       # E2E テスト
└── moon.mod.json
```

## ビルド・テスト

```bash
# ビルド
moon build cmd/main --target native

# 実行
moon run cmd/main -- <command> [args...]

# E2E テスト
bash scripts/e2e_test.sh
```

## 依存関係

```json
{
  "deps": {
    "moonbit-community/sqlite3": "0.1.3",
    "moonbitlang/x": "0.4.41"
  }
}
```

## 関連スキル

- [rust-porting](../rust-porting/SKILL.md) - Rust からの移植ガイド
- [sqlite](../sqlite/SKILL.md) - SQLite 連携
- [testing-strategy](../testing-strategy/SKILL.md) - テスト戦略

## 参考リソース

- [MoonBit 公式サイト](https://www.moonbitlang.com/)
- [beads_rust (元プロジェクト)](https://github.com/Dicklesworthstone/beads_rust)
- [moonbit-community/sqlite3](https://github.com/myfreess/sqlite3.mbt)
