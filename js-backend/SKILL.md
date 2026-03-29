# MoonBit JS Backend Guide

TypeScript/JavaScript CLI ツールの MoonBit 移植ガイド。

## 概要

**TypeScript/JS で書かれた CLI ツールを MoonBit で再実装して `--target=js`（または`preferred-target: "js"`）で出力した場合、ライブラリの有無を除けば、ほぼ同じ機能を実装できます**。ただし、いくつか注意点があります。

### なぜ「ほぼ同じ」といえるか

- **JS backend の成熟度**: MoonBit は**JavaScript backend を正式にサポート**しており、`moon build --target=js` で純粋な JavaScript ファイル（ESM/CJS/IIFE 対応）を出力します。Node.js 環境で直接実行可能（`moon run --target=js` も Node.js 上で動く）。
- **Node.js との統合**: 
  - 公式の JS FFI（`extern "js"`）で`console.log`、`process.argv`、`fs` モジュール、`require("node:fs")` などの Node.js 組み込み API を直接呼び出せます。
  - コミュニティライブラリ（例: **mizchi/js.mbt**）では、**@types/node 相当の bindings**やよく使われる npm パッケージの型安全なラッパーが提供されており、Node.js の標準ライブラリ（fs, path, os, child_process, http など）の多くをかなり自然に使えます。
- **CLI 特有の機能**:
  - 引数解析（`process.argv`経由で自前実装 or FFI で commander/yargs 相当のものをラップ）
  - ファイル読み書き（`fs.readFileSync` / `writeFileSync`など）
  - 標準入出力、環境変数、エラー処理
  - HTTP クライアント（Fetch API ベースの`moonbitlang/async/http`が JS backend 対応）
  - これらは TS/JS の CLI ツールでよく使われるものとほぼ同等に再現可能です。

生成される JS コードは**MoonBit の静的型チェック + パターンマッチ + 代数的データ型**のおかげで、ランタイムの堅牢性が高く、TS より型安全性が強い場合が多いです。また、パフォーマンスが純粋 JS/TS より良いケース（例：JSON 処理で数倍速い報告あり）もあります。

### 「ライブラリの有無を除く」と重要な理由

- **MoonBit のエコシステムはまだ若い**（2026 年現在、1.0 に向けた Beta/0.8.x 段階）。
  - **npm パッケージの直接利用**は限定的。`extern "js"`で個別に FFI を書くか、コミュニティの js bindings（mizchi/js など）を使う必要があります。
  - 人気の CLI ライブラリ（commander, chalk, inquirer, ora, yargs など）は、まだ完全な MoonBit ネイティブ版がないか、部分的に FFI でラップする形になります。
  - TS/JS の CLI では`npm install`一つで即戦力ライブラリが揃うのに対し、MoonBit では**自前実装 or FFI 作業が増える**可能性が高いです。
- 逆に、**コアロジック（アルゴリズム、データ処理、パーサーなど）**は MoonBit の言語機能でよりクリーンに書けます。

## プロジェクト設定

### moon.mod.json

```json
{
  "name": "username/my-cli",
  "preferred-target": "js"
}
```

### 基本的な Node.js FFI 例

```moonbit
// fs モジュールの読み込み
extern "js" fn require(name: String) -> JsValue = "(name) => require(name)"

fn main() -> Unit {
  let fs = require("node:fs")
  let readFileSync = fs.get("readFileSync") |> unsafe_cast((String, String) -> String)
  let content = readFileSync("input.txt", "utf-8")
  println(content)
}
```

### CLI エントリポイント

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

## 出力形式

- **ESM (ECMAScript Modules)** - 最新の Node.js プロジェクト向け
- **CJS (CommonJS)** - 従来の Node.js プロジェクト向け
- **IIFE (Immediately Invoked Function Expression)** - ブラウザ向け

既存の Node.js CLI ワークフローに組み込みやすい。

## デバッグ

- **sourcemap 対応** - MoonBit コードと生成 JS の対応付けが可能
- **Node.js デバッガ** - Chrome DevTools, VS Code などでデバッグ可能
- **ブラウザデバッガ** - JS backend はブラウザでも動作

TS 時代と似た開発体験が得られます。

## ライブラリの現状

### エコシステムの課題

MoonBit のエコシステムはまだ若い（2026 年現在、1.0 に向けた Beta/0.8.x 段階）。

#### 制限事項

- **npm パッケージの直接利用** は限定的
  - `extern "js"` で個別に FFI を書く必要がある
  - コミュニティの js bindings（mizchi/js など）を使う
- **人気の CLI ライブラリ** は完全な MoonBit ネイティブ版がない場合も
  - commander, chalk, inquirer, ora, yargs など
  - FFI でラップする形になる

#### 推奨アプローチ

- **コアロジック**（アルゴリズム、データ処理、パーサーなど）は MoonBit で
- **ライブラリ依存部分** は FFI で JS と連携
- **将来的** にエコシステムが成長すれば逆転する可能性

## おすすめの使い分け

### MoonBit が向いているケース

| 用途 | 理由 |
|------|------|
| **ロジック中心の CLI** | JSON 処理、ファイル変換、シンプルなツール |
| **型安全性重視** | コンパイル時に多くのエラーを検出 |
| **パフォーマンス重視** | 数倍速いケースも |
| **マルチターゲット** | Native + JS + Wasm で同じコード |

### TS/JS のままが良いケース

| 用途 | 理由 |
|------|------|
| **ライブラリ依存が大きい** | カラフル出力、プログレスバー、複雑な引数解析 |
| **迅速なプロトタイピング** | npm install で即戦力ライブラリが揃う |
| **既存エコシステムの活用** | 成熟したライブラリ ecosystem |

## 実践的な移植戦略

### 1. プロトタイプ

```bash
moon new my-cli
cd my-cli
```

`moon.mod.json` を編集：
```json
{
  "preferred-target": "js"
}
```

### 2. 依存関係の追加

```bash
# JS bindings
moon add mizchi/js

# 引数解析（オプション）
moon add moonbit-community/ArgParser
```

### 3. コアロジックの移植

Rust/TS のデータモデルを MoonBit に書き直し：

```typescript
// TypeScript
interface Config {
  name: string;
  value: number;
}

enum Command {
  Add = "add",
  Remove = "remove"
}
```

```moonbit
// MoonBit
struct Config {
  name : String
  value : Int
}

enum Command {
  Add
  Remove
}
```

### 4. ハイブリッドアプローチ

**コアを MoonBit で書き、必要に応じて JS FFI で拡張**するのが現実的：

```moonbit
// コアロジックは MoonBit
fn process_data(input : String) -> Result[String, String] {
  // 複雑な処理
}

// CLI 部分は FFI
extern "js" fn exit(code : Int) -> Unit = "code => process.exit(code)"
```

## 参考リソース

- [MoonBit 公式サイト](https://www.moonbitlang.com/)
- [MoonBit JS Backend ドキュメント](https://docs.moonbitlang.com/)
- [mizchi/js.mbt](https://github.com/mizchi/js.mbt) - Node.js bindings
- [moonbit-community/ArgParser](https://github.com/moonbit-community/ArgParser) - 引数解析
- [moonbitlang/async/http](https://github.com/moonbitlang/async) - HTTP クライアント
