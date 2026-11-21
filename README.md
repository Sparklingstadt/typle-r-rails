# typle-r-rails

typle-r（Next.js）を Ruby on Rails 8.1 で作り直した版です。コマンド・構文・外国語の単語を、打って覚えます。

## 動かす

```bash
bundle install          # gem は vendor/bundle に入ります
bin/rails db:setup      # DB を作り、デモのアカウント（ID demo / パスワード password123）を入れる
bin/rails server -p 3010
```

テスト: `bin/rails test`（サンドボックスなどで並列実行のソケットが使えないときは `PARALLEL_WORKERS=1 bin/rails test`）

## できること

| 画面 | パス | 内容 |
|---|---|---|
| はじめに | `/` | 紹介と、その場で1語打てる欄 |
| ホーム | `/home` | 続きから・今週のまとめ・苦手な単語・次に練習するリスト |
| 練習 | `/play` | タイピング・思い出して打つ（`?mode=recall`）・Handwriting（`?mode=writing`）。`?review=weak` で苦手な単語だけ（記録しない） |
| 練習記録・ベスト記録 | `/records`・`/rankings` | ベストは今の語数の記録を、正確率 → 時間の順に、モードごとに比べる（typle-r と同じ） |
| 単語パック | `/packs` | パック → リスト → 単語の作成・編集・削除・複製・ほかのパックへの移動、パックファイル（`.typle-pack.json`）とリストの CSV の取り込み・書き出し、手書きの言語の印。保存後は typle-r と同じく一覧に戻り、そのパック（`?pack=`）やリスト（`?list=`）を開いて強調し、画面下に通知を出す |
| 単語一覧 | `/words` | すべての単語を検索 |
| 公式パック | `/catalog` | typle-r の 269 リスト（71 パック）。カタログ ID は typle-r と同じ。関心に合うものを先に並べる |
| 一般 | `/settings/general` | 表示言語（日本語・English・简体中文・繁體中文・Русский・Français、Cookie に1年） |
| 入力 | `/settings` | 特殊文字の簡易入力（á→a、ш→sh、ß→ss、¿→?）、大文字・小文字を区別しない。typle-r と同じく、このブラウザーに保存（Cookie） |
| 関心 | `/interests` | 語学・プログラミングとそのタグ。合う公式パックをまとめてフォロー・解除 |
| 端末 | `/devices` | 練習した端末を記録に残す。組み込みの「デフォルト」、未選択、このブラウザーで使う端末（Cookie） |
| アカウント | `/settings/general` | ID・メールアドレスの確認状態、確認メールの再送、パスワードの変更、すべての端末からログアウト（typle-r と同じく一般設定の中） |
| 使い方・Typleについて | `/guide`・`/about`・`/about/licenses` | ライセンス一覧（同梱の gem と onnxruntime-web・PaddleOCR、全文は `/about/licenses.txt`） |
| 共有された結果 | `/result` | X で共有した練習結果をリンクだけから表示（typle-r と同じ。SNS 用の画像は作らない） |

- **ゲスト**: ログインしなくても全部の機能が使えます。データは「このブラウザー」に結び付いたゲストのデータ（署名付き Cookie で識別）としてサーバーに保存し、アカウントとは分けます。ログインしてもコピーせず、ログアウトするとゲストのデータに戻ります。typle-r は LocalStorage に置きますが、ここではサーバーに置く点が違います（Cookie を消すと失われるのは同じ）。
- **ログイン**: ID とパスワード（Rails 8 の authentication）と GitHub（OmniAuth）。パスワードは typle-r と同じく10文字以上で ID と同じものは使えません（上限は bcrypt の72文字）。パスワードを忘れたときは ID を、ID を忘れたときはメールアドレスを入れると、確認済みのメールアドレスにリンクや ID を送ります。
- **Handwriting**: 手書きの言語の印が付いたリストで使えます。OS の手書き入力で入力欄に書くか、韓国語のリストではアプリの手書きパッドに書きます。パッドは PaddleOCR の韓国語の認識モデルを onnxruntime-web でブラウザーの中で動かし、お手本に寄せた判定（CTC の前向きアルゴリズム、差が 3 以内なら受け入れ）も typle-r と同じです。

## デザイン

見た目は typle-r と同じです。typle-r と同じ Tailwind CSS v4 と shadcn/ui のトークン（`app/assets/tailwind/application.css` は typle-r の `globals.css` の写し）、lucide のアイコン、Noto Sans JP を使います。

- 文言の多くは typle-r の `src/messages` をそのまま使います（`config/locales/typle/`、ICU の `{name}`・plural を Rails の形に直したもの。ビューでは `tt("practice.result.title")` のように読みます）
- `app/helpers/ui_helper.rb`: typle-r の `src/components/ui`（Button・Card・Badge・Input・Switch・Table など）を、同じクラスの文字列のヘルパーにしたもの。クラスの重なりは `cn`（tailwind_merge）で typle-r と同じように解きます
- `app/views/layouts/application/`: トップバー・サイドバー・ドロワー（typle-r の Navbar・Sidebar・MobileNav）
- 画面ごとの追加の部品は `app/helpers/*_design_helper.rb`、文言は `config/locales/design/*.yml`（多くは typle-r の `src/messages` から取り込み）
- CSS は `bin/rails tailwindcss:build` で `app/assets/builds/tailwind.css` に作ります。開発中は Puma が監視して作り直します
- テーマはトップバーの太陽・月のボタンで切り替え、typle-r と同じ `typle-r:theme:v1` に保存します

## 設定（環境変数）

| 名前 | 内容 |
|---|---|
| `GITHUB_CLIENT_ID`・`GITHUB_CLIENT_SECRET` | GitHub の OAuth App。コールバック URL は `<オリジン>/auth/github/callback`。ないときは GitHub のボタンを出しません |
| `MAIL_FROM` | メールの差出人 |
| `SMTP_ADDRESS`・`SMTP_PORT`・`SMTP_USERNAME`・`SMTP_PASSWORD` | 本番でメールを送る SMTP |
| `APP_HOST` | 本番のメールに書くリンクのホスト |

開発環境のメールは送らず、`tmp/mails/` にファイルとして書きます。

## コードの場所

- 公式パック: `db/official_lists/`（typle-r の `src/lib/packs/commands/` の写し、順番は `manifest.json`）と `app/models/official_catalog.rb`
- 文字の判定: `app/javascript/typing.js`（typle-r の `src/lib/typing.ts`）、手書きの照合: `app/javascript/writing.js`（`src/lib/writing.ts`）、手書きの認識: `app/javascript/handwriting.js`（`src/lib/handwriting.ts`・`handwritingRecognizer.ts`）
- 練習の画面: `app/javascript/controllers/practice_controller.js`・`writing_controller.js`
- 手書きパッドのモデルと実行環境: `public/handwriting/`（`ko/` のモデルは PaddleOCR、Apache License 2.0。`ort/` は onnxruntime-web 1.31.1、MIT）
- 文言: `config/locales/<言語>.yml`（ja が基準）。テストと開発では足りない訳があるとエラーになります

## typle-r との違い

- ゲストのデータはブラウザーの LocalStorage ではなく、Cookie で結び付けたサーバーのデータです
- パックのファイル（`.typle-pack.json`）の取り込み・書き出し、公式パックの個別ページ（`/packs/<slug>`）、X へのシェア、OGP 画像、アクセス解析はありません
- 単語の編集は行ごとの入力欄（追加・削除・並べ替え・Enter・Alt+↑↓・Ctrl+Enter・CSV の読み込み）。typle-r の読み込みダイアログ（プレビュー・置き換え）はなく、末尾に追加します
- パックはリストから作ります（typle-r と同じ）。パックのカテゴリ・タグの欄はなく、リストのものを表示します
- 練習の途中で別のリストを選んでも確認しません
