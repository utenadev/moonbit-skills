# MoonBit WASM CLI Development Guide

WebAssembly (WASM) CLI 開発ガイド。MoonBit の強みを最も活かせるシナリオ。

## 概要

**MoonBit で WASM CLI を開発するのは非常に適しており、MoonBit の強みを最も活かせるシナリオの一つ**です。

MoonBit は「Wasm-first」言語として設計されており、**wasm-gc**（WebAssembly GC）バックエンドがデフォルトで優秀です。Rust CLI からの移植や、従来の JS/TS CLI の代替としても有力です。

## ターゲット

| ターゲット | 説明 | 推奨 |
|-----------|------|------|
| **wasm-gc** | GC 対応の現代的な Wasm | ✅ 推奨 |
| **wasm** | 旧来の非 GC 版 | △ |

### wasm-gc の特徴

- **ブラウザサポート**: Chrome 119+, Firefox 120+, Safari 18.2+ でネイティブサポート
- **出力サイズ**: 小さい
- **起動速度**: 速い
- **GC 対応**: ガベージコレクション自動管理

## WASI（WebAssembly System Interface）

WASI により、CLI に必要なシステム機能が利用可能。

### サポート状況

- **WASI Preview 1/2** 対応
- **Component Model** 対応
- **WIT（WebAssembly Interface Types）** で型安全にホストとやり取り可能

### 実行環境

| 環境 | コマンド例 | 備考 |
|------|-----------|------|
| **wasmtime** | `wasmtime run your-cli.wasm -- arg1 arg2` | 最も一般的 |
| **WasmEdge** | `wasmedge your-cli.wasm arg1 arg2` | 軽量 |
| **Spin** | `spin up` | Fermyon 製サーバーレス |
| **Node.js** | `node --experimental-wasi your-cli.wasm` | experimental |
| **ブラウザ** | - | 一部制限あり |

## CLI 開発の利点

| 利点 | 説明 |
|------|------|
| **小さなバイナリサイズ** | Rust よりさらにコンパクトなケース多し |
| **高速コンパイル** | 開発体験抜群 |
| **型安全性** | パターンマッチ・Result/Option が Rust 並みに強い |
| **クロスプラットフォーム** | 同じコードで JS backend や native にも展開可能 |
| **ポータビリティ** | wasmtime 一つでどこでも動く |
| **セキュリティ** | サンドボックス環境で安全 |

## 開発の始め方

### 1. プロジェクト作成

```bash
moon new my-wasm-cli --lib   # または --bin
cd my-wasm-cli
```

### 2. ターゲット設定

`moon.mod.json` を編集：

```json
{
  "name": "my-wasm-cli",
  "preferred-target": "wasm-gc",
  "supported-targets": ["wasm-gc"]
}
```

### 3. WASI 対応のテンプレートを使う（おすすめ）

- GitHub の **moonbit-community/wasi-cli-template** を参考に。
- または公式ドキュメントの WASI/Component Model 例を基に。

### 4. ビルドと実行

```bash
moon build --target wasm-gc --release
# 出力：target/wasm-gc/release/build/.../main.wasm

# 実行例（wasmtime 使用）
wasmtime run target/wasm-gc/release/build/main/main.wasm -- --help
```

**必要ツール**:
- `wasm-tools`（Component embed 用）
- `wasmtime`（実行）
- `wit-bindgen`（高度な Component Model の場合）

## WASI で使える主な機能（CLI 向け）

- **標準入出力**: `println!`、`eprintln!`、`read_line` など（WASI 経由でホストの stdio にマッピング）。
- **コマンドライン引数**: `env::args()` 相当の API。
- **ファイルシステム**: WASI fs（ファイル読み書き、ディレクトリ操作）。
- **環境変数**: `env::var()` など。
- **エラー処理**: MoonBit の`Result` + `?` で堅牢に。

## 実装例

### シンプルな CLI エントリポイント

```moonbit
fn main() -> Unit {
  let args = env::args()  // WASI 対応の引数取得
  
  match parse_args(args) {
    Result::Ok(cmd) => { run(cmd) }
    Result::Err(e) => {
      eprintln("Error: " + e)
      exit(1)
    }
  }
}
```

### WASI ファイルアクセス（Preview 1）

**プロジェクト設定**:
```bash
moon add moonbit-community/wasip1
```

**ファイル読み書き例**:
```moonbit
///| using moonbit-community/wasip1/fs as fs
///| using moonbit-community/wasip1/env as env

fn main() -> Unit {
  // コマンドライン引数取得
  let args = env::args()

  // 例：引数で指定されたファイルを読み込んで加工し、別ファイルに書き込む
  match args {
    [_, input_path, output_path, ..] => {
      // ファイル読み込み
      match fs::read_to_string(input_path) {
        Result::Ok(content) => {
          println("Read " + content.length().to_string() + " bytes from " + input_path)

          // 簡単な加工例（ここにロジックを入れる）
          let processed = content.uppercase()

          // ファイル書き込み
          match fs::write_string(output_path, processed) {
            Result::Ok(_) => { println("Written to " + output_path) }
            Result::Err(e) => {
              eprintln("Write error: " + e)
              exit(1)
            }
          }
        }
        Result::Err(e) => {
          eprintln("Read error: " + e)
          exit(1)
        }
      }
    }
    _ => {
      println("Usage: " + args[0] + " <input> <output>")
      exit(1)
    }
  }
}
```

**主な fs API 例**（wasip1/fs から）:
- `fs::read_to_string(path: String) -> Result[String, Error]`
- `fs::write_string(path: String, content: String) -> Result[Unit, Error]`
- `fs::open` / `fd_read` / `fd_write` などの低レベル API も利用可能
- ディレクトリ操作（`readdir` など）も一部サポート

**実行方法**（wasmtime 使用）:
```bash
# ビルド
moon build --target wasm-gc --release

# 実行（事前に --dir=. でカレントディレクトリを preopen）
wasmtime run --dir=. target/wasm-gc/release/build/main/main.wasm -- input.txt output.txt
```

**注意**:
- WASI は **sandboxed** なので、実行時に `--dir=/path/to/allow` でアクセス許可ディレクトリを明示的に指定する必要があります。
- エラー処理は必ず `Result` + `match` or `?`（try!）を使い、パターンマッチで網羅的に扱うのが MoonBit らしい書き方です。

## 引数解析のベストプラクティス

**おすすめライブラリ**:
1. **moonbit-community/ArgParser**（シンプル・宣言的）← **初心者・小〜中規模 CLI に最適**
2. **TheWaWaR/clap**（より本格的、Rust の clap に近い機能）

**ArgParser の使い方例**:
```moonbit
///| using moonbit-community/ArgParser {parse, Spec, Set, Set_string}

fn main() -> Unit {
  let verbose = Ref::new(false)
  let output = Ref::new("default.out")
  let files : Array[String] = []

  let spec : Array[(String, String, Spec, String)] = [
    ("--verbose", "-v", Set(verbose), "verbose mode"),
    ("--output", "-o", Set_string(output), "output file path"),
    // positional arguments は別途扱う
  ]

  match parse(spec, env::args()) {
    Result::Ok(_) => {
      if verbose.val { println("Verbose enabled") }
      println("Output to: " + output.val)

      // 残りの positional args を files に集めるロジックなど
      // ...
    }
    Result::Err(msg) => {
      eprintln("Error: " + msg)
      show_usage()
      exit(1)
    }
  }
}

fn show_usage() -> Unit {
  println(#|
    Usage: mytool [OPTIONS] [FILES...]
    Options:
      -v, --verbose    Enable verbose output
      -o, --output     Output file path
  |)
}
```

**ベストプラクティス**:
- **宣言的スタイル**を活用（spec 配列でオプションを定義）。コードが読みやすく、メンテしやすい。
- 小規模 CLI → ArgParser で十分。
- 中〜大規模（サブコマンド、複雑なバリデーション） → `clap.mbt` を検討。
- 自前実装する場合：`Array[String]` を `match` やループで解析。パターンマッチが強いので、`enum Command { Help, Run { input: String, ... } }` を作って変換すると型安全。
- **エラーハンドリング**: 解析失敗時は必ず usage を表示 + 非ゼロ終了。
- **ヘルプ生成**: spec から自動生成できるようにするか、手動で `#|` raw string でメンテ。
- WASI Component Model を使う場合：`wasi-cli` world を WIT で定義し、`wit-bindgen` で bindings 生成すると、さらに型安全に `args_get` などが扱える（将来的に推奨）。

## Component Model のファイルアクセス例

**WIT ファイル作成**（`wit/world.wit` 例）:
```wit
package mycli:tool@0.1.0;

world run {
  import wasi:cli/environment@0.2.0;
  import wasi:cli/stdin@0.2.0;
  import wasi:cli/stdout@0.2.0;
  import wasi:cli/stderr@0.2.0;
  import wasi:cli/run@0.2.0;          // CLI 実行エントリ
  import wasi:filesystem/types@0.2.0; // ファイルシステム
  import wasi:filesystem/preopens@0.2.0; // preopen ディレクトリ

  export wasi:cli/run@0.2.0;  // 自分の CLI を実装
}
```

**依存 WIT の取得と bindings 生成**:
```bash
wit-deps update   # または wkg wit update
wit-bindgen moonbit wit/ --out-dir . --derive-eq --derive-show --derive-error
```

**Component Model を使ったファイルアクセス例**:
```moonbit
///| using wasi:filesystem/types as fs
///| using wasi:filesystem/preopens as preopens

fn main() -> Unit {
  // preopen されたディレクトリ/ファイルを取得（sandboxed）
  let preopens = preopens::get_preopens()  // Array[(String, fs::Descriptor)]

  // 例：カレントディレクトリ相当の descriptor を探す（シンプル化）
  match find_preopen(".".to_string(), preopens) {
    Option::Some(root_desc) => {
      // 相対パスでファイルを開く
      match root_desc.open_at("input.txt", fs::OpenFlags::read_only(), fs::Modes::read()) {
        Result::Ok(file_desc) => {
          // ファイルを読み込む
          match read_all_from_descriptor(file_desc) {
            Result::Ok(content) => {
              println("File content: " + content)
              // 加工例
              let upper = content.uppercase()
              write_to_stdout(upper)
            }
            Result::Err(e) => {
              eprintln("Read error: " + e)
              exit(1)
            }
          }
        }
        Result::Err(e) => {
          eprintln("Open error: " + e)
          exit(1)
        }
      }
    }
    Option::None => {
      eprintln("No preopen found for current dir")
      exit(1)
    }
  }
}

// ヘルパー関数例：descriptor から全データを読み込む
fn read_all_from_descriptor(desc : fs::Descriptor) -> Result[String, fs::Error] {
  let mut buffer = Bytes::new(4096)
  let mut result = ""

  loop {
    match desc.read_via_stream(0, 4096) {  // offset, length
      Result::Ok(stream) => {
        match streams::read_all(stream) {  // または read
          Result::Ok(data) => {
            if data.length() == 0 { break }  // EOF
            result = result + data.to_string()  // または encoding 利用
          }
          Result::Err(e) => return Result::Err(e)
        }
      }
      Result::Err(e) => return Result::Err(e)
    }
  }

  Result::Ok(result)
}
```

**主な API のポイント**（wasi:filesystem/types）:
- **Descriptor** リソース：ファイルやディレクトリのハンドル。
- `open_at(parent: Descriptor, path: String, flags: OpenFlags, modes: Modes) -> Result[Descriptor, Error]`
- `read_via_stream(offset: U64, length: U64) -> Result[InputStream, Error]`
- `write_via_stream(...)`
- `preopens::get_preopens()` で実行時に許可されたパスを取得（`--dir=.` 相当）。
- エラーは `result<..., error-code>` や専用 `Error` 型で扱う。

**ビルド・実行フロー**:
```bash
# MoonBit ビルド
moon build --target wasm-gc --release

# Component 化（重要！）
wasm-tools component embed wit/ target/wasm-gc/release/build/.../main.wasm \
  --encoding utf16 -o mytool.wasm

wasm-tools component new mytool.wasm -o mytool.component.wasm
```

**実行例（wasmtime）**:
```bash
wasmtime run --dir=. mytool.component.wasm -- input.txt
```

- `--dir=.`（または `--dir=/allowed:path`）で sandbox 内のアクセスを許可。
- Component Model では、**preopens** で明示的に許可されたディレクトリのみアクセス可能（セキュリティが高い）。

## 開発 Tips（WASI CLI 全体）

| Tip | 説明 |
|-----|------|
| **テンプレートおすすめ** | `moonbit-community/wasi-cli-template` をクローンして始めると、build/run スクリプト（just など）が揃っていて便利 |
| **デバッグ** | `wasmtime --debug` や `--dir=.:.` でファイルアクセスを許可しながらテスト |
| **Component Model 移行** | シンプルな CLI は Preview 1 で OK。HTTP や高度な機能が必要なら `wit-bindgen-moonbit` + wasi-cli/wasi-http へ移行 |
| **ポータビリティ** | 同じコードで `--target wasm-gc` と JS backend を両方サポート可能（一部条件コンパイル） |
| **エラー処理** | `Result` + `match` または `?` を徹底（MoonBit の強み） |
| **ファイルパス** | 相対パス中心。絶対パスは preopen 次第で制限される |
| **大きなファイル** | ストリーミング（`InputStream` / `OutputStream`）で扱う |
| **コミュニティパッケージ** | `peter-jerry-ye/wasi-imports` などのラッパーを使うと便利 |

## 注意点と今後の展望

### 現状の制限

- **エコシステム** - Rust ほどではない
- **WASI/Component Model** - 急速に充実中（2025-2026 で大幅進化）
- **複雑な CLI** - `wit-bindgen-moonbit` でインターフェース定義が必要

### 今後の展望

- **1.0 リリース**（2026 年中予定）でさらに安定化
- **WASI Preview 2** - より多くのシステム機能
- **Component Model** - 型安全なコンポーネント連携

## デバッグ

| ツール | 用途 |
|--------|------|
| `wasmtime --debug` | デバッグモード実行 |
| Wasm デバッガ | 対応デバッガで使用 |
| sourcemap | MoonBit コードと Wasm の対応付け |

## 参考リソース

- [MoonBit 公式サイト](https://www.moonbitlang.com/)
- [MoonBit WASI ドキュメント](https://docs.moonbitlang.com/)
- [moonbit-community/wasi-cli-template](https://github.com/moonbit-community/wasi-cli-template)
- [moonbit-community/wasip1](https://github.com/moonbit-community/wasip1) - WASI bindings
- [Wasmtime](https://wasmtime.dev/) - WASM ランタイム
- [WASI 仕様](https://github.com/WebAssembly/WASI)
