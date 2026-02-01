# アフィリエイター向けSEO・収益管理ダッシュボード - MVP機能設計書（完全版）
作成日：2026年2月1日

## 目次
1. [MVP開発の基本方針](#mvp開発の基本方針)
2. [機能の優先順位付けフレームワーク](#機能の優先順位付けフレームワーク)
3. [Phase 1: MVP必須機能（1～2ヶ月）](#phase-1-mvp必須機能1～2ヶ月)
4. [Phase 2: 強化機能（2～3ヶ月）](#phase-2-強化機能2～3ヶ月)
5. [Phase 3: 差別化機能（3～6ヶ月）](#phase-3-差別化機能3～6ヶ月)
6. [除外する機能（当面実装しない）](#除外する機能当面実装しない)
7. [ユーザーストーリーとユースケース](#ユーザーストーリーとユースケース)
8. [技術的実現可能性の検証](#技術的実現可能性の検証)
9. [**NEW: UI/UX設計とワイヤーフレーム**](#uiux設計とワイヤーフレーム)
10. [**NEW: 競合分析と差別化戦略**](#競合分析と差別化戦略)
11. [**NEW: 開発環境セットアップ**](#開発環境セットアップ)
12. [**NEW: 技術実装詳細設計**](#技術実装詳細設計)

---

## MVP開発の基本方針

### MVPの定義
**MVP（Minimum Viable Product）= 最小限の機能で最大の価値検証を実現するプロダクト**

このプロジェクトにおけるMVPの目的：
1. **価値仮説の検証**：アフィリエイターは本当にこのツールにお金を払うか？
2. **コア価値の提供**：最も重要な課題（SEO順位管理と収益一元化）を解決できるか？
3. **早期フィードバック**：実際のユーザーからの学びを最大化する

### Must-have vs Nice-to-have の判断基準

各機能を以下の基準で評価：

| 基準 | Must-have（必須） | Nice-to-have（あると良い） |
|------|------------------|------------------------|
| **価値検証への貢献** | 直接的に貢献する | 間接的・補助的 |
| **ユーザーの課題解決** | コア課題を解決 | 利便性向上 |
| **開発コスト** | 許容範囲内 | 高コスト・複雑 |
| **技術的リスク** | 低～中リスク | 高リスク |
| **差別化要素** | 競合と同等で十分 | 競合より優れる |

---

## 機能の優先順位付けフレームワーク

### RICE スコアリング

各機能を以下の4要素で評価：
- **Reach（到達度）**：何人のユーザーに影響するか？（1～10点）
- **Impact（影響度）**：ユーザー体験にどれだけ影響するか？（0.25/0.5/1/2/3点）
- **Confidence（確信度）**：効果の確信度は？（50%/80%/100%）
- **Effort（工数）**：開発に何日かかるか？（人日）

**RICEスコア = (Reach × Impact × Confidence) / Effort**

---

## Phase 1: MVP必須機能（1～2ヶ月）

### 🎯 目標
**「アフィリエイターが日々使いたくなる最小限のツール」を提供し、課金意欲を検証する**

### 機能リスト

#### 1. ユーザー認証・管理
**優先度：P0（最高）** | **RICE: 10 × 3 × 100% / 3日 = 10.0**

**機能概要**
- メールアドレス + パスワードでの新規登録・ログイン
- パスワードリセット機能
- 基本的なプロフィール管理（名前、メールアドレス）

**実装詳細**
- Devise gem を使用（Rails標準の認証機能）
- メール送信：Action Mailer + Gmail SMTP（初期）
- セッション管理：Cookie-based

**なぜMust-have？**
- すべての機能の前提となる
- セキュリティの基盤
- ユーザーデータの分離に必須

---

#### 2. サイト登録・管理
**優先度：P0（最高）** | **RICE: 10 × 3 × 100% / 2日 = 15.0**

**機能概要**
- サイトの新規登録（サイト名、URL、説明）
- サイトの編集・削除
- サイト一覧表示

**実装詳細**
```ruby
# モデル設計
class Site < ApplicationRecord
  belongs_to :user
  has_many :keywords
  has_many :articles
  
  validates :name, presence: true
  validates :url, presence: true, url: true
end
```

**制限事項（MVP）**
- 無料プラン：3サイトまで
- 有料プラン：10サイトまで

**なぜMust-have？**
- ツールの中心的なエンティティ
- 後続のすべての機能の基礎

---

#### 3. キーワード登録・管理
**優先度：P0（最高）** | **RICE: 10 × 3 × 100% / 3日 = 10.0**

**機能概要**
- サイトごとにキーワードを登録
- キーワードの編集・削除
- キーワード一覧表示（サイト別）
- 対象URL（記事URL）の紐付け

**実装詳細**
```ruby
# モデル設計
class Keyword < ApplicationRecord
  belongs_to :site
  belongs_to :article, optional: true
  has_many :rank_histories
  
  validates :word, presence: true
  validates :target_url, url: true, allow_blank: true
end
```

**制限事項（MVP）**
- 無料プラン：サイトあたり10キーワードまで
- 有料プラン：サイトあたり100キーワードまで

**なぜMust-have？**
- SEO管理の核心
- ユーザーが最も追跡したいデータ

---

#### 4. 検索順位の自動取得
**優先度：P0（最高）** | **RICE: 10 × 3 × 80% / 7日 = 3.4**

**機能概要**
- Google検索での順位を自動取得（100位まで）
- 日次で自動実行（深夜バッチ処理）
- 順位履歴の保存

**実装詳細**

**方法1：Google Custom Search API（推奨・MVP）**
```ruby
# Gemfile
gem 'google-api-client'

# app/services/rank_checker_service.rb
class RankCheckerService
  def initialize(keyword, site_url)
    @keyword = keyword
    @site_url = site_url
    @client = Google::Apis::CustomsearchV1::CustomSearchAPIService.new
    @client.key = ENV['GOOGLE_API_KEY']
  end
  
  def check_rank
    results = @client.list_cses(
      q: @keyword,
      cx: ENV['GOOGLE_SEARCH_ENGINE_ID'],
      num: 10 # 一度に10件取得
    )
    
    rank = find_rank_in_results(results)
    return rank if rank
    
    # 100位まで繰り返し取得
    (2..10).each do |page|
      start_index = (page - 1) * 10 + 1
      results = @client.list_cses(
        q: @keyword,
        cx: ENV['GOOGLE_SEARCH_ENGINE_ID'],
        num: 10,
        start: start_index
      )
      rank = find_rank_in_results(results, start_index - 1)
      return rank if rank
    end
    
    nil # 100位圏外
  end
  
  private
  
  def find_rank_in_results(results, offset = 0)
    results.items&.each_with_index do |item, index|
      if item.link.include?(@site_url)
        return offset + index + 1
      end
    end
    nil
  end
end
```

**Sidekiqバッチ処理**
```ruby
# app/jobs/daily_rank_check_job.rb
class DailyRankCheckJob < ApplicationJob
  queue_as :default
  
  def perform
    Keyword.find_each do |keyword|
      rank = RankCheckerService.new(keyword.word, keyword.site.url).check_rank
      keyword.rank_histories.create!(
        rank: rank || 101, # 圏外は101として保存
        checked_at: Time.current
      )
      
      sleep 1 # API制限対策（1秒待機）
    end
  end
end
```

**API制限と費用**
- Google Custom Search API：無料枠 100クエリ/日
- 有料：$5 / 1,000クエリ
- MVP段階では無料枠内で運用（ユーザー制限で調整）

**なぜMust-have？**
- ツールのコア機能
- 手動チェックの自動化がユーザーの最大ペインポイント

---

#### 5. 検索順位ダッシュボード（基本）
**優先度：P0（最高）** | **RICE: 10 × 3 × 100% / 5日 = 6.0**

**機能概要**
- サイト別のキーワード一覧
- 現在の順位表示
- 前日比の変動表示（▲▼）
- 簡易なグラフ表示（折れ線グラフ、直近30日）

**画面構成**
```
┌─────────────────────────────────────┐
│ ダッシュボード                         │
├─────────────────────────────────────┤
│ サイト選択: [ドロップダウン]            │
├─────────────────────────────────────┤
│ キーワード    現在順位  前日比  30日推移│
├─────────────────────────────────────┤
│ ブログ SEO    3位      ▲2    [グラフ] │
│ Rails 開発    12位     ▼1    [グラフ] │
│ MVP 作り方    8位      →     [グラフ] │
└─────────────────────────────────────┘
```

**実装詳細**
- グラフライブラリ：Chart.js（軽量、学習コスト低）
- Hotwire Turbo Framesでサイト切り替え時も高速

**なぜMust-have？**
- 取得したデータを可視化しないと価値がない
- ユーザーが毎日見たくなる画面

---

#### 6. アフィリエイト収益の手動入力
**優先度：P1（高）** | **RICE: 8 × 2 × 100% / 3日 = 5.3**

**機能概要**
- 月次でASP別の収益を手動入力
- ASP名、収益額、対象月を記録
- 収益推移グラフの表示

**実装詳細**
```ruby
# モデル設計
class Revenue < ApplicationRecord
  belongs_to :site
  
  validates :asp_name, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :month, presence: true
end
```

**画面構成**
```
┌─────────────────────────────────────┐
│ 収益管理                             │
├─────────────────────────────────────┤
│ + 新規収益を追加                      │
├─────────────────────────────────────┤
│ ASP名       対象月      収益額        │
├─────────────────────────────────────┤
│ A8.net     2026年1月   ¥45,320      │
│ Amazon     2026年1月   ¥12,850      │
│ 楽天       2026年1月   ¥8,490       │
├─────────────────────────────────────┤
│ 合計                   ¥66,660       │
└─────────────────────────────────────┘
```

**なぜP1（MVP必須だが優先度はやや下）？**
- 手動入力なら開発コスト低い
- 収益一元化はツールの差別化ポイント
- ただし、順位チェックより優先度は低い

**Phase 2で自動化を検討**
- API連携（A8.net、Amazonアソシエイト等）

---

#### 7. シンプルなレポート機能
**優先度：P1（高）** | **RICE: 7 × 1 × 100% / 2日 = 3.5**

**機能概要**
- 月次サマリーの表示
  - 平均順位の推移
  - 順位が上がったキーワード数
  - 順位が下がったキーワード数
  - 月間収益合計

**画面構成**
```
┌─────────────────────────────────────┐
│ 月次レポート - 2026年1月              │
├─────────────────────────────────────┤
│ 📈 平均順位: 15.3位 (前月比: ▲2.1)   │
│ ⬆️  順位UP: 8キーワード               │
│ ⬇️  順位DOWN: 3キーワード             │
│ 💰 月間収益: ¥66,660 (前月比: +12%) │
└─────────────────────────────────────┘
```

**なぜMust-have？**
- 定期的な成果確認でユーザーのモチベーション維持
- データの価値を実感させる

---

### Phase 1 の制約事項

**意図的に実装しない機能：**
1. ❌ キーワード調査・提案機能 → Phase 2
2. ❌ 記事管理機能 → Phase 2
3. ❌ 競合サイト分析 → Phase 3
4. ❌ ASP自動連携 → Phase 2
5. ❌ チーム機能・共有 → Phase 3
6. ❌ モバイルアプリ → Phase 3以降

**技術的な制約：**
- データベース：PostgreSQL
- 順位取得：Google Custom Search API（無料枠制限あり）
- ユーザー数制限：クローズドベータ 10～20名
- キーワード数制限：1ユーザー最大30キーワード（API制限対策）

---

## Phase 2: 強化機能（2～3ヶ月）

Phase 1でのユーザーフィードバックを元に実装優先度を調整。以下は想定リスト。

### 1. キーワード調査機能
**優先度：P1（高）** | **推定工数：5～7日**

**機能概要**
- 検索ボリュームの表示
- 関連キーワードの提案
- 競合性の評価

**技術検討**
- Google Keyword Planner API
- または、スクレイピング（利用規約要確認）

---

### 2. 記事管理機能
**優先度：P1（高）** | **推定工数：5日**

**機能概要**
- 記事のステータス管理（下書き、公開、リライト予定）
- キーワードと記事の紐付け強化
- 記事別の順位・収益表示

---

### 3. ASP自動連携
**優先度：P2（中）** | **推定工数：10～15日**

**機能概要**
- A8.net、Amazonアソシエイト等のAPI連携
- 自動で収益データ取得
- サイト別・記事別の収益自動振り分け

**技術課題**
- 各ASPのAPI仕様が異なる
- A8.netは公式APIなし→スクレイピング検討（グレーゾーン）

---

### 4. アラート・通知機能
**優先度：P2（中）** | **推定工数：3日**

**機能概要**
- 順位が大幅に変動したらメール通知
- 目標順位達成時の通知
- 月次レポートの自動配信

---

### 5. リライト優先度の自動提案
**優先度：P2（中）** | **推定工数：5日**

**機能概要**
- 順位下落が大きい記事を自動抽出
- 収益性が高いのに順位が低い記事を推奨
- リライト候補リストの生成

---

## Phase 3: 差別化機能（3～6ヶ月）

### 1. 競合サイト分析
**優先度：P3（低）** | **推定工数：10日**

**機能概要**
- 競合サイトの登録
- 同一キーワードでの競合順位追跡
- 競合との順位差の可視化

---

### 2. AI活用コンテンツ提案
**優先度：P3（低）** | **推定工数：15日**

**機能概要**
- OpenAI API連携
- 記事タイトル・見出しの自動生成
- リライト提案文の自動作成

---

### 3. チーム機能
**優先度：P3（低）** | **推定工数：7日**

**機能概要**
- 複数ユーザーでサイトを共同管理
- 権限管理（オーナー、編集者、閲覧者）
- コメント・メモ機能

---

## 除外する機能（当面実装しない）

以下の機能は、MVP検証の範囲外として**意図的に除外**します：

### 1. ❌ 被リンク分析
**理由**
- 競合ツール（Ahrefs、Majestic等）が強すぎる
- 開発コストが非常に高い
- 差別化要素として弱い

---

### 2. ❌ コンテンツSEOスコア
**理由**
- 既存ツール（EmmaTools、ラッコキーワード等）で十分
- アルゴリズム開発が複雑
- MVP検証には不要

---

### 3. ❌ サイト表示速度チェック
**理由**
- Google PageSpeed Insightsで無料で使える
- ツールの差別化に寄与しない

---

### 4. ❌ SNS連携・投稿管理
**理由**
- スコープが広がりすぎる
- 別ツール（Buffer、Hootsuiteなど）で代替可能

---

## ユーザーストーリーとユースケース

### ペルソナ定義

**ペルソナ1：副業アフィリエイター「田中さん」**
- 年齢：35歳、会社員（IT企業）
- 運営サイト：2サイト（ブログ形式）
- 記事数：各サイト50記事程度
- 月間収益：3～5万円
- 課題：
  - 本業が忙しく、SEO管理に時間を割けない
  - どの記事をリライトすべきか判断できない
  - 複数ASPの収益管理が煩雑

**ペルソナ2：専業アフィリエイター「佐藤さん」**
- 年齢：29歳、フリーランス
- 運営サイト：5サイト
- 記事数：合計300記事以上
- 月間収益：30～50万円
- 課題：
  - 手動での順位チェックが限界
  - サイトごとの収益性を正確に把握したい
  - 効率的な記事管理ツールが欲しい

---

### ユーザーストーリー

#### ストーリー1：初回セットアップ
```
As a 副業アフィリエイター
I want サイトとキーワードを簡単に登録できる
So that すぐにツールを使い始められる

Acceptance Criteria:
- 5分以内にサイトとキーワードを登録できる
- サイトURL、キーワードの入力だけで完了
- 初回順位取得が24時間以内に完了
```

#### ストーリー2：日次チェック
```
As a 専業アフィリエイター
I want 毎朝ログインして順位変動を一目で確認できる
So that 迅速にリライト判断ができる

Acceptance Criteria:
- ダッシュボードで全サイトの順位変動を一覧表示
- 大きな変動（±5位以上）を目立たせる
- 前日比、1週間比を表示
```

#### ストーリー3：月次振り返り
```
As a 副業アフィリエイター
I want 月次レポートで成果を確認できる
So that SEO施策の効果を測定できる

Acceptance Criteria:
- 月次の平均順位、順位変動を自動集計
- 収益推移をグラフで表示
- 前月比を％で表示
```

---

## 技術的実現可能性の検証

### 1. 検索順位取得の技術選択

#### 方法A：Google Custom Search API（推奨）
**メリット**
- ✅ 公式API、利用規約違反のリスクなし
- ✅ 実装が簡単
- ✅ 安定性が高い

**デメリット**
- ❌ 無料枠が少ない（100クエリ/日）
- ❌ 有料化すると費用がかさむ（$5/1000クエリ）

**MVP段階での対応**
- クローズドベータでユーザー数を制限（10～20名）
- 1ユーザーあたりキーワード数を制限（最大30）
- 日次バッチ処理で効率化

---

#### 方法B：スクレイピング（非推奨・将来検討）
**メリット**
- ✅ コストがかからない
- ✅ 取得件数の制限なし

**デメリット**
- ❌ Google利用規約に抵触する可能性
- ❌ IPブロックのリスク
- ❌ HTML構造変更で動かなくなる

**結論**
- MVP段階ではGoogle Custom Search APIを使用
- Phase 2以降、ユーザー数増加に応じて検討

---

### 2. データベース設計（MVP）

```ruby
# ER図（主要テーブル）

users
  - id
  - email
  - encrypted_password
  - name
  - plan (free/basic/pro)
  - created_at, updated_at

sites
  - id
  - user_id (FK)
  - name
  - url
  - description
  - created_at, updated_at

keywords
  - id
  - site_id (FK)
  - word
  - target_url (記事URL)
  - created_at, updated_at

rank_histories
  - id
  - keyword_id (FK)
  - rank (integer, 101=圏外)
  - checked_at (date)
  - created_at

revenues
  - id
  - site_id (FK)
  - asp_name
  - amount (decimal)
  - month (date)
  - created_at, updated_at
```

---

### 3. インフラ構成（MVP）

**ホスティング**
- Heroku（推奨）または Fly.io
- 理由：デプロイが簡単、スケール容易、初期無料枠あり

**データベース**
- PostgreSQL（Heroku Postgres）

**バックグラウンドジョブ**
- Sidekiq + Redis
- 順位チェックバッチ処理に使用

**モニタリング**
- Heroku Dashboard（基本）
- Sentry（エラー追跡）

**推定コスト**
- 開発環境：無料
- 本番環境（ベータ）：月額 $7～$25
- 本番環境（正式）：月額 $50～$100

---

## 開発スケジュール（Phase 1: 6～8週間）

### Week 1-2：環境構築＋基盤開発
- [ ] Railsプロジェクト作成
- [ ] Devise認証実装
- [ ] 基本レイアウト・デザインシステム適用
- [ ] Herokuへの初回デプロイ

### Week 3-4：コア機能実装
- [ ] サイト登録・管理機能
- [ ] キーワード登録・管理機能
- [ ] Google Custom Search API連携
- [ ] 順位取得ロジック実装
- [ ] Sidekiqバッチ処理実装

### Week 5-6：ダッシュボード＋収益管理
- [ ] 順位ダッシュボード画面
- [ ] グラフ表示（Chart.js）
- [ ] 収益手動入力機能
- [ ] 月次レポート機能

### Week 7-8：テスト＋改善
- [ ] 統合テスト・バグ修正
- [ ] パフォーマンス最適化
- [ ] クローズドベータ準備
- [ ] ドキュメント作成

---

## 成功指標（KPI）- MVP段階

### プロダクトKPI
1. **アクティブ率**：週1回以上ログインするユーザー > 70%
2. **継続率**：30日後も使い続けているユーザー > 50%
3. **満足度**：NPS（Net Promoter Score） > 30

### ビジネスKPI
1. **課金意向**：ベータユーザーの課金意向率 > 40%
2. **推奨意向**：「友人に勧めたい」と答えるユーザー > 50%

### 技術KPI
1. **順位取得成功率**：> 95%
2. **ページ表示速度**：ダッシュボード読み込み < 2秒
3. **システム稼働率**：> 99%

---

## UI/UX設計とワイヤーフレーム

### プロダクト名と ブランディング

**推奨プロダクト名：「RankFlow（ランクフロー）」**
- コンセプト：順位の「流れ」を可視化し、収益を「流す」
- 短くて覚えやすい
- 国際展開も視野に入れた英語名

### デザインシステム

**カラーパレット**
```css
:root {
  --color-primary: #0D9488;      /* Teal-600 - プライマリアクション */
  --color-primary-hover: #0F766E;
  --color-success: #10B981;       /* 順位UP */
  --color-danger: #EF4444;        /* 順位DOWN */
  --color-warning: #F59E0B;       /* 変動注意 */
}
```

### 主要画面ワイヤーフレーム

#### ダッシュボード（メイン画面）
```
┌─────────────────────────────────────────────────────┐
│ [Logo] RankFlow    サイト: [マイブログ ▼]   [田中] │
├─────────────────────────────────────────────────────┤
│  📊 ダッシュボード                                   │
│  ┌──────────────────────────────────────────┐      │
│  │ サイト概要                                │      │
│  │ 平均順位: 12.5位 (前日比: ▲1.2)          │      │
│  │ 今月の収益: ¥45,320 (前月比: +8%)        │      │
│  └──────────────────────────────────────────┘      │
│  ┌──────────────────────────────────────────┐      │
│  │ キーワード一覧              [+ 追加]      │      │
│  ├─────┬──────┬─────┬────────────────┤      │
│  │キーワード│現在順位│前日比│30日推移       │      │
│  ├─────┼──────┼─────┼────────────────┤      │
│  │ブログ SEO│ 3位 │ ▲2  │ [折れ線グラフ]│      │
│  │Rails 開発│ 12位│ ▼1  │ [折れ線グラフ]│      │
│  └─────┴──────┴─────┴────────────────┘      │
└─────────────────────────────────────────────────────┘
```

---

## 競合分析と差別化戦略

### 主要競合比較

| ツール | 価格 | 順位チェック | キーワード調査 | 収益管理 | Mac対応 | クラウド |
|--------|------|--------------|----------------|----------|---------|----------|
| **GRC** | ¥4,950/年 | ⭐⭐⭐⭐⭐ | ❌ | ❌ | ❌ | ❌ |
| **Rank Tracker** | ¥21,000/年 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ | ✅ | ❌ |
| **RankFlow** | ¥9,800/年 | ⭐⭐⭐⭐ | ❌（Phase2） | ⭐⭐⭐⭐⭐ | ✅ | ✅ |

### 価格戦略

**3層プラン構成**

1. **Freeプラン（¥0/月）**
   - サイト数：1
   - キーワード数：5
   - 目的：トライアル・リード獲得

2. **Basicプラン（¥980/月、¥9,800/年）** ← メインターゲット
   - サイト数：3
   - キーワード数：サイトあたり30
   - 収益管理：無制限ASP
   - ターゲット：副業アフィリエイター

3. **Proプラン（¥2,980/月、¥29,800/年）**
   - サイト数：10
   - キーワード数：サイトあたり100
   - 競合分析（Phase 2）
   - ターゲット：専業アフィリエイター

### 4つの差別化ポイント

1. **アフィリエイト収益管理（最大の差別化）**
   - SEO順位と収益を同一画面で確認
   - どのキーワードが稼いでいるか一目瞭然

2. **クラウド・マルチデバイス対応**
   - スマホ、Mac、Windowsどこからでもアクセス可能
   - GRC・Rank Trackerはインストール型

3. **アフィリエイター特化UI/UX**
   - 日本のASP（A8.net、Amazon等）に最適化
   - 初心者でも5分でセットアップ完了

4. **適正価格（GRCの2倍、Rank Trackerの半額）**
   - GRC（¥4,950）より多機能
   - Rank Tracker（¥21,000）より安価

---

## 開発環境セットアップ

### 前提条件
```bash
ruby 3.2.2 以上
rails 7.1.0 以上
postgresql 14.x 以上
redis 7.x 以上
```

### プロジェクト作成
```bash
# Railsアプリ作成
rails new rankflow \
  --database=postgresql \
  --css=tailwind \
  --javascript=hotwire

cd rankflow

# DB作成
rails db:create

# Git初期化
git init
git add .
git commit -m "Initial commit"
```

### 必須Gem構成

**Gemfile抜粋**
```ruby
# Authentication
gem "devise", "~> 4.9"

# Background Jobs
gem "sidekiq", "~> 7.2"
gem "sidekiq-cron", "~> 1.11"

# API Integration
gem "google-apis-customsearch_v1", "~> 0.14"

# Frontend
gem "turbo-rails"
gem "stimulus-rails"
gem "chartkick", "~> 5.0"  # グラフ表示
```

### Herokuデプロイ設定

```bash
# Herokuアプリ作成
heroku create rankflow-mvp

# アドオン追加
heroku addons:create heroku-postgresql:mini
heroku addons:create heroku-redis:mini

# 環境変数設定
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)
heroku config:set GOOGLE_API_KEY=your_api_key
heroku config:set GOOGLE_SEARCH_ENGINE_ID=your_cx_id

# デプロイ
git push heroku main
```

**Procfile**
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
release: bundle exec rails db:migrate
```

---

## 技術実装詳細設計

### データベース完全設計

#### マイグレーションファイル

**1. Usersテーブル**
```ruby
class DeviseCreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :name, null: false
      t.string :plan, null: false, default: "free"
      
      t.timestamps null: false
    end
    
    add_index :users, :email, unique: true
  end
end
```

**2. Sitesテーブル**
```ruby
class CreateSites < ActiveRecord::Migration[7.1]
  def change
    create_table :sites do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :url, null: false
      t.text :description
      
      t.timestamps
    end
  end
end
```

**3. Keywordsテーブル**
```ruby
class CreateKeywords < ActiveRecord::Migration[7.1]
  def change
    create_table :keywords do |t|
      t.references :site, null: false, foreign_key: true
      t.string :word, null: false
      t.string :target_url
      
      t.timestamps
    end
    
    add_index :keywords, [:site_id, :word], unique: true
  end
end
```

**4. RankHistoriesテーブル**
```ruby
class CreateRankHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :rank_histories do |t|
      t.references :keyword, null: false, foreign_key: true
      t.integer :rank, null: false
      t.date :checked_at, null: false
      
      t.timestamps
    end
    
    add_index :rank_histories, [:keyword_id, :checked_at], unique: true
  end
end
```

**5. Revenuesテーブル**
```ruby
class CreateRevenues < ActiveRecord::Migration[7.1]
  def change
    create_table :revenues do |t|
      t.references :site, null: false, foreign_key: true
      t.string :asp_name, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :month, null: false
      
      t.timestamps
    end
    
    add_index :revenues, [:site_id, :asp_name, :month], unique: true
  end
end
```

### モデル実装（主要メソッド）

**Site Model**
```ruby
class Site < ApplicationRecord
  belongs_to :user
  has_many :keywords, dependent: :destroy
  has_many :revenues, dependent: :destroy
  
  # 平均順位を計算
  def average_rank(date = Date.today)
    keywords.joins(:rank_histories)
            .where(rank_histories: { checked_at: date })
            .where('rank_histories.rank <= 100')
            .average('rank_histories.rank')
            .to_f.round(1)
  end
  
  # 月次収益合計
  def total_revenue(month = Date.today.beginning_of_month)
    revenues.where(month: month).sum(:amount)
  end
end
```

**Keyword Model**
```ruby
class Keyword < ApplicationRecord
  belongs_to :site
  has_many :rank_histories, dependent: :destroy
  
  # 最新順位
  def current_rank
    rank_histories.order(checked_at: :desc).first&.rank || 101
  end
  
  # 前日比
  def rank_change
    today = rank_histories.find_by(checked_at: Date.today)&.rank
    yesterday = rank_histories.find_by(checked_at: Date.yesterday)&.rank
    return nil unless today && yesterday
    yesterday - today  # 正の値 = 順位UP
  end
end
```

### Google Custom Search API実装

**RankCheckerService**
```ruby
require 'google/apis/customsearch_v1'

class RankCheckerService
  def initialize(keyword_word, site_url)
    @keyword_word = keyword_word
    @site_url = normalize_url(site_url)
    @client = Google::Apis::CustomsearchV1::CustomSearchAPIService.new
    @client.key = ENV['GOOGLE_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_ENGINE_ID']
  end
  
  def check_rank
    (1..10).each do |page|
      start_index = (page - 1) * 10 + 1
      results = fetch_search_results(start_index)
      rank = find_rank_in_results(results, start_index - 1)
      return rank if rank
      sleep 1
    end
    101  # 圏外
  rescue Google::Apis::Error => e
    Rails.logger.error("API Error: #{e.message}")
    nil
  end
  
  private
  
  def fetch_search_results(start_index)
    @client.list_cses(
      q: @keyword_word,
      cx: @cx,
      num: 10,
      start: start_index,
      gl: 'jp',
      lr: 'lang_ja'
    )
  end
  
  def find_rank_in_results(results, offset)
    return nil unless results&.items
    results.items.each_with_index do |item, index|
      if normalize_url(item.link).include?(@site_url)
        return offset + index + 1
      end
    end
    nil
  end
  
  def normalize_url(url)
    url.to_s.downcase.gsub(/^https?:\/\/(www\.)?/, '').gsub(/\/$/, '')
  end
end
```

### Sidekiqバックグラウンドジョブ

**config/sidekiq.yml**
```yaml
:concurrency: 5
:queues:
  - default

:schedule:
  daily_rank_check:
    cron: '0 2 * * *'  # 毎日午前2時（UTC）
    class: DailyRankCheckJob
    queue: default
```

**DailyRankCheckJob**
```ruby
class DailyRankCheckJob < ApplicationJob
  queue_as :default
  
  def perform
    Keyword.find_each do |keyword|
      RankCheckWorkerJob.perform_later(keyword.id)
      sleep 1  # API制限対策
    end
  end
end
```

**RankCheckWorkerJob**
```ruby
class RankCheckWorkerJob < ApplicationJob
  queue_as :default
  
  def perform(keyword_id)
    keyword = Keyword.find(keyword_id)
    return if keyword.rank_histories.exists?(checked_at: Date.today)
    
    rank = RankCheckerService.new(keyword.word, keyword.site.url).check_rank
    
    if rank
      keyword.rank_histories.create!(
        rank: rank,
        checked_at: Date.today
      )
    end
  end
end
```

---

## 次のアクション

この完全版設計書で、以下が完備されました：

✅ **MVP機能設計** - Phase 1～3の全機能定義
✅ **UI/UX設計** - ワイヤーフレーム、デザインシステム
✅ **競合分析** - GRC・Rank Tracker比較、価格戦略
✅ **開発環境** - Rails初期化、Herokuデプロイ手順
✅ **技術実装** - DB設計、API実装、バックグラウンドジョブ

### 開発開始の準備完了！

**今すぐ始められること：**

1. **環境構築（30分）**
   ```bash
   rails new rankflow --database=postgresql --css=tailwind --javascript=hotwire
   ```

2. **Google API設定（20分）**
   - Cloud Consoleでプロジェクト作成
   - Custom Search API有効化

3. **Week 1開発スタート**
   - Devise認証実装
   - 基本レイアウト構築
   - Heroku初回デプロイ

どの部分から進めますか？または、特定の実装について詳しく知りたい箇所はありますか？
