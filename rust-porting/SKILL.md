# Rust CLI Porting Guide

MoonBit での Rust CLI ツール移植ガイド。

## 言語的な親和性

MoonBit は「Rust の良い部分を取り入れつつ、lifetime の複雑さを排除した」言語。

### 良い点

- **静的型付け** - コンパイル時に型エラーを検出
- **Pattern Matching** - exhaustive matching で網羅性チェック
- **Option/Result** - Rust と同様のエラー処理
- **enum/struct** - Rust と似た構文
- **ジェネリクス** - 型パラメータサポート
- **GC 付き** - 所有権・借用の複雑さなし

### パフォーマンス

- 特定の数値計算で **Rust より 30% 程度速い** ケースも
- CLI 全体では差が小さいことが多い
- コンパイルが **10〜100 倍速い**（開発体験が良い）

## コンパイルターゲット

| ターゲット | 用途 | 備考 |
|-----------|------|------|
| **Native** | ネイティブ CLI | C/LLVM 経由、`.exe` やバイナリ出力 |
| **JS** | Node.js 環境 | `mizchi/js.mbt` で Node.js API を型安全に使用 |
| **Wasm-GC** | ブラウザ/WASI | WASI CLI も可能 |

## 機能対応表

Rust CLI の主要機能を MoonBit でどう再現するか。

| 機能 | Rust | MoonBit | 移植のしやすさ |
|------|------|---------|---------------|
| **引数解析** | `clap`, `structopt` | `moonbit-community/ArgParser`, `@sys.get_cli_args()` | ◎ |
| **ファイル/パス** | `std::fs`, `std::path` | `moonbitlang/x/fs`, `mizchi/js/node/fs` | ◎ |
| **標準入出力** | `std::io`, `std::env` | 標準ライブラリサポート | ◎ |
| **エラー処理** | `anyhow`, `thiserror` | `Result` + `try/catch`, `?` 演算子 | ◎ |
| **JSON 処理** | `serde`, `serde_json` | 組み込み `Json` 型 | ○ |
| **カラフル出力** | `colored` | JS: `mizchi/js` で一部、Native: 自前 | △ |
| **HTTP** | `reqwest` | `moonbitlang/async/http`, Fetch API | ○ |
| **外部コマンド** | `std::process::Command` | JS: `child_process`, Native: FFI | ○ |

### 移植のしやすさの目安

- **シンプルなユーティリティ CLI** → **非常にしやすい**
  - ファイル変換、JSON 処理、テキストパーサーなど
  - Rust コードをほぼそのままの感覚で書き直せる

- **clap を多用した複雑 CLI** → **1〜2 日で代替可能**
  - 引数パーサーライブラリの置き換えが必要
  - 宣言的 API なので代替は容易

- **TUI や高度なターミナル制御** → **現在は手間が増える**
  - 成熟度はまだ低い
  - 将来的に改善の見込みあり

## 移植フロー

### 1. プロジェクト作成

```bash
moon new my-cli
cd my-cli
```

### 2. ターゲット設定

`moon.mod.json` を編集：

```json
{
  "name": "username/my-cli",
  "preferred-target": "native",
  "deps": {}
}
```

### 3. コアロジックの移植

Rust のデータモデルを MoonBit に書き直し：

```rust
// Rust
pub struct Config {
    pub name: String,
    pub value: i32,
}

pub enum Command {
    Add { name: String },
    Remove { id: u32 },
}
```

```moonbit
// MoonBit
pub struct Config {
  name : String
  value : Int
}

pub enum Command {
  Add(String)
  Remove(Int)
}
```

### 4. CLI エントリポイント

```moonbit
fn main() -> Unit {
  let args = @sys.get_cli_args()
  
  match parse_args(args) {
    Result::Ok(cmd) => { run_command(cmd) }
    Result::Err(e) => { 
      println("error: " + e)
    }
  }
}
```

### 5. 依存関係の追加

```bash
# JS backend の場合
moon add mizchi/js

# 引数解析
moon add moonbit-community/ArgParser
```

## 特別なツール

### mbt_rs (Rust ↔ MoonBit transpiler)

- **リポジトリ**: `mizchi/mbt_rs`
- **機能**: Rust コードを MoonBit に自動変換
- **用途**: 単一ファイルの移植に有効
- **制限**: 完全な自動変換ではない、手動調整が必要

### mizchi/js.mbt

- **用途**: JS backend で Node.js API を使用
- **機能**: `fs`, `path`, `process`, `child_process` など
- **メリット**: 型安全に Node.js 標準 API を使用可能

## メリット・デメリット

### メリット

1. **開発スピード**
   - コンパイルが高速（10〜100 倍）
   - GC でメモリ管理のストレス減少

2. **マルチターゲット**
   - 同じコードで Native + JS + Wasm
   - 書き換えなしで複数プラットフォーム対応

3. **AI 支援開発**
   - MoonBit は AI native を標榜
   - コード生成・補完との相性が良い

4. **バイナリサイズ**
   - 特に Wasm で小さめ
   - 配布が容易

### デメリット

1. **エコシステムの成熟度**
   - Rust ほどライブラリが豊富ではない
   - CLI 周辺の便利クレートが少ない

2. **Native backend**
   - まだ「experimental」寄り
   - 急速に改善中だが、安定性は Rust に劣る

3. **パフォーマンスチューニング**
   - Rust の所有権システムほどの細かい制御はできない
   - 通常用途では問題ないレベル

## おすすめ戦略

### 初心者向け

1. **JS backend + mizchi/js** でプロトタイプ
   - Node.js 環境なら一番楽
   - 既存の npm パッケージも活用可能

2. **本番は native backend**
   - スタンドアロン CLI に
   - 配布が容易

### 上級者向け

**ハイブリッドアプローチ**:
- コア部分だけ MoonBit に移植
- 周辺は Rust のまま
- FFI で連携（ただし手間増）

## 実例：beads_mbt

Rust 版 [beads_rust](https://github.com/Dicklesworthstone/beads_rust) の MoonBit 移植プロジェクト。

### 実装済み機能

- ✅ CLI コマンド（18 コマンド）
- ✅ SQLite ストレージ
- ✅ 依存関係管理
- ✅ ラベル管理
- ✅ コメント機能
- ✅ 全文検索

### 使用したパッケージ

```json
{
  "deps": {
    "moonbit-community/sqlite3": "0.1.3",
    "moonbitlang/x": "0.4.41"
  }
}
```

### 学んだこと

1. **引数解析** - `@sys.get_cli_args()` がシンプルで効果的
2. **エラー処理** - `try/catch` パターンの確立
3. **SQLite** - `prepare` → `bind` → `step` → `finalize` パターン
4. **テスト** - E2E テストが効果的（12/12 成功）

リポジトリ：https://github.com/utenadev/beads_mbt

## 参考リソース

- [MoonBit 公式サイト](https://www.moonbitlang.com/)
- [MoonBit ドキュメント](https://docs.moonbitlang.com/)
- [mooncakes.io](https://mooncakes.io/) - パッケージレジストリ
- [moonbit-community/ArgParser](https://github.com/moonbit-community/ArgParser)
- [mizchi/js.mbt](https://github.com/mizchi/js.mbt)
- [mizchi/mbt_rs](https://github.com/mizchi/mbt_rs)
