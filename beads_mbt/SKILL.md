# beads_mbt Project Skills

beads_mbt プロジェクト固有の開発スキル。

> パス、バージョン、依存関係などの事実は、対象リポジトリ（beads_mbt）の
> `moon.mod` と `AGENTS.md` が正。本ファイルの記載と食い違う場合はそちらを優先する。

## プロジェクト概要

beads_mbt は、Rust で実装された [beads_rust](https://github.com/Dicklesworthstone/beads_rust) を MoonBit に移植したプロジェクトです。

- **目的**: Git リポジトリ向けのローカルファーストなイシュートラッカー
- **リポジトリ**: https://github.com/utenadev/beads_mbt
- **ターゲット**: Native（`preferred_target = "native"`）
- **DB**: SQLite（`.beads/beads.db` に保存）

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
├── moon.mod              # モジュール定義（依存関係はここが正）
├── moon.pkg              # ルートパッケージ
├── beads_mbt.mbt         # ルートパッケージ本体
├── beads_mbt_test.mbt    # blackbox テスト
├── beads_mbt_wbtest.mbt  # whitebox テスト
├── cmd/
│   └── bm/               # CLI パッケージ（実行ファイル名は bm）
│       ├── main.mbt
│       ├── cli.mbt
│       ├── commands.mbt
│       ├── organization.mbt
│       ├── query.mbt
│       └── moon.pkg
├── lib/
│   ├── model.mbt         # データモデル
│   ├── storage.mbt       # SQLite ストレージ
│   ├── util.mbt          # ユーティリティ
│   └── moon.pkg
├── scripts/
│   ├── e2e_test.sh       # E2E テスト
│   └── run_tests.sh
├── justfile              # fmt / check / test / ci などのタスク定義
└── .skills/              # 本スキル集（moonbit-skills のサブモジュール）
```

## ビルド・テスト

```bash
# ビルド
moon build cmd/bm --target native

# 実行
moon run cmd/bm -- <command> [args]

# インストール（~/.moon/bin に bm として配置）
moon install ./cmd/bm

# CI 相当のチェック一式（fmt / info / check / test）
just ci

# E2E テスト
bash scripts/e2e_test.sh
```

## 依存関係

`moon.mod` の import が正。2026-10-23 時点の内容は次の通り。

```
name = "utenadev/beads_mbt"
version = "0.2.1"

import {
  "moonbit-community/sqlite3@0.2.3",
  "moonbitlang/x@0.5.5",
}
```

## 関連スキル

- [rust-porting](../rust-porting/SKILL.md) - Rust からの移植ガイド
- [sqlite](../sqlite/SKILL.md) - SQLite 連携
- [testing-strategy](../testing-strategy/SKILL.md) - テスト戦略

## 参考リソース

- [MoonBit 公式サイト](https://www.moonbitlang.com/)
- [beads_rust (元プロジェクト)](https://github.com/Dicklesworthstone/beads_rust)
- [moonbit-community/sqlite3.mbt](https://github.com/moonbit-community/sqlite3.mbt)
