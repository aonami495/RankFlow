# RankFlow（ランクフロー）

**日本のアフィリエイターのための SEO順位・収益管理ダッシュボード**

![Ruby](https://img.shields.io/badge/Ruby-3.2-red)
![Rails](https://img.shields.io/badge/Rails-7.2-red)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## 概要

RankFlow は、日本のアフィリエイターのために開発された **SEO検索順位と収益を一元管理できるダッシュボードツール** です。

海外製ツール（Rank Tracker 等）の「高機能すぎる」「英語で使いにくい」という課題を解決し、**必要な機能だけに絞り込みました**。

### こんな悩みを解決します

- 毎日の順位チェックが面倒...
- 複数ASPの収益をExcelで管理するのが大変...
- どの記事をリライトすべきか分からない...
- 高機能すぎるツールは使いこなせない...

---

## 特徴（こだわり）

### 完全日本語対応

画面、エラーメッセージ、日付フォーマットまで **日本仕様に最適化**。
海外製ツールにありがちな「英語だらけで使いにくい」問題を完全解消しました。

### 順位×収益の可視化

**どの記事が稼いでいるか** を一目で把握。
SEO順位と収益を同一画面で確認でき、リライト優先度の判断が簡単になります。

### スマホ完全対応

**通勤中でもスマホで順位チェックが可能**。
レスポンシブデザインにより、PC・タブレット・スマートフォンすべてで快適に操作できます。

### シンプル設計

必要な機能だけに絞り込んだ **シンプルで直感的なUI**。
5分でセットアップ完了、すぐに使い始められます。

---

## 機能一覧

### コア機能

| 機能           | 説明                                        |
| -------------- | ------------------------------------------- |
| サイト管理     | 複数サイトを一元管理                        |
| キーワード管理 | サイトごとにキーワードを登録・追跡          |
| 順位自動取得   | Google検索順位を日次で自動取得（100位まで） |
| 順位履歴       | 過去の順位変動をグラフで可視化              |
| 収益管理       | ASP別の収益を記録・集計                     |
| 記事管理       | 記事とキーワードを紐付けて管理              |
| アラート       | 順位変動をメールで通知                      |
| 月次レポート   | 成果を自動集計してレポート生成              |

### 高度な機能

| 機能             | 説明                                |
| ---------------- | ----------------------------------- |
| 競合分析         | 競合サイトの順位を追跡              |
| AIコンテンツ提案 | OpenAI連携でリライト提案を自動生成  |
| チーム機能       | 複数メンバーでサイトを共同管理      |
| ASP連携          | 各ASPとのAPI連携（対応ASP順次追加） |

---

## 技術スタック

### バックエンド

- **Ruby** 3.2
- **Ruby on Rails** 7.2
- **PostgreSQL** - データベース
- **Redis** - キャッシュ・セッション管理
- **Sidekiq** - バックグラウンドジョブ

### フロントエンド

- **Hotwire（Turbo / Stimulus）** - SPA風の高速なページ遷移
- **Tailwind CSS** - モダンなスタイリング
- **Noto Sans JP** - 日本語最適化フォント
- **Chartkick / Chart.js** - グラフ可視化

### 外部API

- **Google Custom Search API** - 検索順位取得（gl=jp で日本向け）
- **OpenAI API** - AIコンテンツ提案（オプション）

### インフラ

- **Heroku** / **Fly.io** 対応
- **Action Mailer** - メール通知

---

## セットアップ

### 前提条件

```bash
Ruby 3.2.x
PostgreSQL 14.x 以上
Redis 7.x 以上
Node.js 18.x 以上
```

### インストール

```bash
# リポジトリのクローン
git clone https://github.com/yourusername/rankflow.git
cd rankflow

# 依存関係のインストール
bundle install

# データベースのセットアップ
rails db:create
rails db:migrate
rails db:seed

# Tailwind CSSのビルド
rails tailwindcss:build
```

### 環境変数の設定

`.env` ファイルを作成し、以下の環境変数を設定してください。

```bash
# Google Custom Search API
GOOGLE_API_KEY=your_google_api_key
GOOGLE_CSE_ID=your_custom_search_engine_id

# OpenAI API（オプション：AIコンテンツ提案機能を使用する場合）
OPENAI_API_KEY=your_openai_api_key

# Redis（本番環境）
REDIS_URL=redis://localhost:6379/0

# メール設定（本番環境）
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password
```

### サーバーの起動

```bash
# Rails サーバー
bin/rails server

# Sidekiq（別ターミナル）
bundle exec sidekiq

# Tailwind CSS watch（開発時、別ターミナル）
rails tailwindcss:watch
```

アプリケーションは http://localhost:3000 で起動します。

---

## Google Custom Search API の設定

1. [Google Cloud Console](https://console.cloud.google.com/) でプロジェクトを作成
2. Custom Search API を有効化
3. APIキーを発行
4. [Programmable Search Engine](https://programmablesearchengine.google.com/) で検索エンジンを作成
5. 検索エンジンID（cx）を取得
6. 環境変数に設定

---

## 開発

### テストの実行

```bash
# 全テスト実行
bundle exec rspec

# 特定のテスト実行
bundle exec rspec spec/models/
bundle exec rspec spec/services/
```

### コードスタイル

```bash
# RuboCop によるリント
bundle exec rubocop

# 自動修正
bundle exec rubocop -a
```

### N+1クエリ検出

開発環境では Bullet gem により N+1 クエリを自動検出します。

---

## デプロイ

### Heroku へのデプロイ

```bash
# Heroku アプリ作成
heroku create your-app-name

# アドオン追加
heroku addons:create heroku-postgresql:mini
heroku addons:create heroku-redis:mini

# 環境変数設定
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)
heroku config:set GOOGLE_API_KEY=your_api_key
heroku config:set GOOGLE_CSE_ID=your_cse_id

# デプロイ
git push heroku main

# データベースマイグレーション
heroku run rails db:migrate
```

---

## プロジェクト構成

```
rankflow/
├── app/
│   ├── controllers/     # コントローラー
│   ├── models/          # モデル
│   ├── views/           # ビュー（ERB）
│   ├── services/        # サービスクラス
│   ├── jobs/            # バックグラウンドジョブ
│   └── helpers/         # ヘルパー
├── config/
│   ├── locales/         # 日本語化ファイル
│   └── routes.rb        # ルーティング
├── db/
│   ├── migrate/         # マイグレーション
│   └── schema.rb        # スキーマ
└── spec/                # テスト
```

---

## ライセンス

MIT License

---

## コントリビューション

1. Fork する
2. Feature ブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチをプッシュ (`git push origin feature/amazing-feature`)
5. Pull Request を作成

---

## お問い合わせ

バグ報告や機能リクエストは [Issues](https://github.com/aonami495/rankflow/issues) にお願いします。

---

<p align="center">
  <strong>RankFlow</strong> - 日本のアフィリエイターのために
</p>
