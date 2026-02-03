# アフィリエイター向けSEO・収益管理ダッシュボード - 包括的開発ガイド

**作成日：2026年2月1日**  
**対象：Phase 1 MVP開発（6～8週間）**

---

## 📑 目次

### Part 1: UI/UX設計とワイヤーフレーム
1. [デザインシステムとブランディング](#デザインシステムとブランディング)
2. [ユーザーフロー図](#ユーザーフロー図)
3. [画面構成とワイヤーフレーム](#画面構成とワイヤーフレーム)

### Part 2: 競合分析と差別化戦略
4. [競合SEOツール詳細比較](#競合seoツール詳細比較)
5. [価格戦略とポジショニング](#価格戦略とポジショニング)
6. [差別化ポイントの明確化](#差別化ポイントの明確化)

### Part 3: 開発環境セットアップ
7. [Railsプロジェクト初期化](#railsプロジェクト初期化)
8. [必須Gem・ライブラリ構成](#必須gemライブラリ構成)
9. [Herokuデプロイ設定](#herokuデプロイ設定)

### Part 4: 技術実装詳細設計
10. [データベース詳細設計](#データベース詳細設計)
11. [Google Custom Search API実装](#google-custom-search-api実装)
12. [バックグラウンドジョブ設計](#バックグラウンドジョブ設計)

---

# Part 1: UI/UX設計とワイヤーフレーム

## デザインシステムとブランディング

### プロダクト名の提案

**候補1：「RankFlow（ランクフロー）」**
- コンセプト：順位の「流れ」を可視化し、収益を「流す」
- 短くて覚えやすい
- .comドメイン取得可能性：中

**候補2：「AffiTrack（アフィトラック）」**
- コンセプト：アフィリエイトを追跡する
- 明確な用途
- .comドメイン取得可能性：高

**候補3：「SEOdash（エスイーオーダッシュ）」**
- コンセプト：SEOダッシュボード
- シンプルで直感的
- .comドメイン取得可能性：中

**推奨：RankFlow** - ブランディング性と覚えやすさのバランスが最良

---

### カラーパレット

**プライマリカラー（Teal/青緑系）**
```css
:root {
  /* プライマリ */
  --color-primary: #0D9488;      /* Teal-600 */
  --color-primary-hover: #0F766E; /* Teal-700 */
  --color-primary-light: #5EEAD4; /* Teal-300 */
  
  /* セカンダリ */
  --color-secondary: #6366F1;     /* Indigo-500 */
  
  /* 背景 */
  --color-bg-primary: #F9FAFB;    /* Gray-50 */
  --color-bg-secondary: #FFFFFF;  /* White */
  
  /* テキスト */
  --color-text-primary: #111827;  /* Gray-900 */
  --color-text-secondary: #6B7280; /* Gray-500 */
  
  /* ステータスカラー */
  --color-success: #10B981;       /* Green-500 - 順位UP */
  --color-danger: #EF4444;        /* Red-500 - 順位DOWN */
  --color-warning: #F59E0B;       /* Amber-500 - 変動注意 */
  --color-info: #3B82F6;          /* Blue-500 */
}
```

**理由**
- Tealは信頼感とプロフェッショナル性を演出
- SEOツールで一般的な青系と差別化
- データ可視化に適した視認性

---

### タイポグラフィ

**フォント選択**
```css
:root {
  /* 日本語優先 */
  --font-family-base: 
    'Noto Sans JP', 
    -apple-system, 
    BlinkMacSystemFont, 
    'Segoe UI', 
    'Helvetica Neue', 
    sans-serif;
  
  /* 数字・データ表示用 */
  --font-family-mono: 
    'JetBrains Mono', 
    'Fira Code', 
    monospace;
}
```

**フォントサイズスケール**
```css
:root {
  --text-xs: 0.75rem;   /* 12px - 補足情報 */
  --text-sm: 0.875rem;  /* 14px - 標準テキスト */
  --text-base: 1rem;    /* 16px - 本文 */
  --text-lg: 1.125rem;  /* 18px - サブタイトル */
  --text-xl: 1.25rem;   /* 20px - 小見出し */
  --text-2xl: 1.5rem;   /* 24px - セクション見出し */
  --text-3xl: 1.875rem; /* 30px - ページタイトル */
}
```

---

## ユーザーフロー図

### フロー1：初回登録からダッシュボード到達まで

```
[ランディングページ]
    ↓
    「無料で始める」ボタン
    ↓
[サインアップページ]
  ・メールアドレス入力
  ・パスワード設定
  ・利用規約同意
    ↓
  [登録完了メール送信]
    ↓
  メール内リンククリック
    ↓
[オンボーディング - Step 1]
  「サイトを登録しましょう」
  ・サイト名入力
  ・サイトURL入力
    ↓
  [次へ]
    ↓
[オンボーディング - Step 2]
  「追跡したいキーワードを登録」
  ・キーワード入力（最大5個）
  ・対象URLを任意で入力
    ↓
  [登録完了]
    ↓
[ダッシュボード（初回）]
  ・「順位取得中...24時間以内に結果が表示されます」
  ・チュートリアルツアー表示
```

---

### フロー2：日常的な利用パターン

```
[ログイン]
    ↓
[ダッシュボード]
  ├─ サイト切り替え（ドロップダウン）
  │  ↓
  │ [キーワード一覧表示]
  │  ・現在順位
  │  ・前日比
  │  ・30日推移グラフ
  │
  ├─ キーワード追加
  │  ↓
  │ [モーダル表示]
  │  ・キーワード入力
  │  ・対象URL入力
  │  ↓
  │ [保存]
  │  ↓
  │ ダッシュボードに戻る
  │
  ├─ 収益入力
  │  ↓
  │ [収益管理ページ]
  │  ・ASP名選択/入力
  │  ・金額入力
  │  ・対象月選択
  │  ↓
  │ [保存]
  │
  └─ レポート閲覧
     ↓
    [月次レポートページ]
     ・平均順位推移
     ・順位変動サマリー
     ・収益推移グラフ
```

---

## 画面構成とワイヤーフレーム

### 1. ダッシュボード（メイン画面）

```
┌─────────────────────────────────────────────────────┐
│ [Logo] RankFlow    サイト: [マイブログ ▼]   [田中] │
├─────────────────────────────────────────────────────┤
│                                                     │
│  📊 ダッシュボード                                   │
│                                                     │
│  ┌──────────────────────────────────────────┐      │
│  │ サイト概要                                │      │
│  │ 平均順位: 12.5位 (前日比: ▲1.2)          │      │
│  │ 今月の収益: ¥45,320 (前月比: +8%)        │      │
│  └──────────────────────────────────────────┘      │
│                                                     │
│  ┌──────────────────────────────────────────┐      │
│  │ キーワード一覧              [+ 追加]      │      │
│  ├─────┬──────┬─────┬────────────────┤      │
│  │キーワード│現在順位│前日比│30日推移       │      │
│  ├─────┼──────┼─────┼────────────────┤      │
│  │ブログ SEO│ 3位 │ ▲2  │ [折れ線グラフ]│      │
│  │Rails 開発│ 12位│ ▼1  │ [折れ線グラフ]│      │
│  │MVP 作り方│ 8位 │ →   │ [折れ線グラフ]│      │
│  │個人開発  │ 15位│ ▲5  │ [折れ線グラフ]│      │
│  └─────┴──────┴─────┴────────────────┘      │
│                                                     │
│  [詳細レポート]  [収益管理]  [設定]                │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**主要要素：**
- サイト切り替えドロップダウン（最上部）
- サマリーカード（平均順位、収益）
- キーワード一覧テーブル
- インライングラフ（Chart.js）
- アクションボタン（追加、詳細、収益、設定）

---

### 2. キーワード追加モーダル

```
┌─────────────────────────────────────────┐
│  キーワードを追加             [✕]       │
├─────────────────────────────────────────┤
│                                         │
│  キーワード                             │
│  [                          ]           │
│  例: ブログ 収益化                      │
│                                         │
│  対象URL（任意）                        │
│  [                          ]           │
│  例: https://example.com/blog/post123   │
│                                         │
│  ℹ️ 順位は翌日の朝に取得されます        │
│                                         │
│         [キャンセル]  [追加]            │
│                                         │
└─────────────────────────────────────────┘
```

---

### 3. 収益管理ページ

```
┌─────────────────────────────────────────────────────┐
│ [Logo] RankFlow    サイト: [マイブログ ▼]   [田中] │
├─────────────────────────────────────────────────────┤
│                                                     │
│  💰 収益管理                        [+ 収益を追加]  │
│                                                     │
│  ┌──────────────────────────────────────────┐      │
│  │ 月次収益推移                              │      │
│  │ [棒グラフ: 過去6ヶ月]                     │      │
│  └──────────────────────────────────────────┘      │
│                                                     │
│  ┌──────────────────────────────────────────┐      │
│  │ 2026年1月の収益                           │      │
│  ├────────────┬───────────┬──────────┤      │
│  │ ASP名       │ 対象月      │ 収益額   │      │
│  ├────────────┼───────────┼──────────┤      │
│  │ A8.net      │ 2026年1月   │ ¥45,320  │      │
│  │ Amazon      │ 2026年1月   │ ¥12,850  │      │
│  │ 楽天        │ 2026年1月   │ ¥8,490   │      │
│  ├────────────┴───────────┼──────────┤      │
│  │ 合計                        │ ¥66,660  │      │
│  └────────────────────────┴──────────┘      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

### 4. 月次レポートページ

```
┌─────────────────────────────────────────────────────┐
│ [Logo] RankFlow    サイト: [マイブログ ▼]   [田中] │
├─────────────────────────────────────────────────────┤
│                                                     │
│  📈 月次レポート - 2026年1月                        │
│                                                     │
│  ┌────────────┬────────────┬────────────┐        │
│  │ 平均順位    │ 順位UP     │ 順位DOWN   │        │
│  │ 15.3位      │ 8キーワード │ 3キーワード│        │
│  │ (▲2.1)     │            │            │        │
│  └────────────┴────────────┴────────────┘        │
│                                                     │
│  ┌──────────────────────────────────────────┐      │
│  │ 月間収益                                  │      │
│  │ ¥66,660 (前月比: +12%)                   │      │
│  └──────────────────────────────────────────┘      │
│                                                     │
│  ┌──────────────────────────────────────────┐      │
│  │ 平均順位の推移（過去6ヶ月）               │      │
│  │ [折れ線グラフ]                            │      │
│  └──────────────────────────────────────────┘      │
│                                                     │
│  ┌──────────────────────────────────────────┐      │
│  │ 最も成長したキーワード                     │      │
│  │ 1. ブログ SEO (20位 → 3位)               │      │
│  │ 2. 個人開発 (25位 → 15位)                │      │
│  │ 3. Rails MVP (18位 → 12位)               │      │
│  └──────────────────────────────────────────┘      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

### レスポンシブ対応

**モバイル版（375px幅）**
```
┌────────────────────┐
│ ☰  RankFlow   👤  │
├────────────────────┤
│ サイト: [▼]        │
│                    │
│ 平均順位: 12.5位   │
│ 今月: ¥45,320      │
│                    │
│ キーワード  [+]    │
│ ┌──────────────┐  │
│ │ブログ SEO      │  │
│ │3位 ▲2         │  │
│ │[ミニグラフ]    │  │
│ └──────────────┘  │
│ ┌──────────────┐  │
│ │Rails 開発      │  │
│ │12位 ▼1        │  │
│ │[ミニグラフ]    │  │
│ └──────────────┘  │
│                    │
└────────────────────┘
```

---

# Part 2: 競合分析と差別化戦略

## 競合SEOツール詳細比較

### 主要競合ツール

#### 1. GRC（国内シェアNo.1）

**概要**
- 国内で最も普及している検索順位チェックツール
- Windows専用（Mac版はGRCモバイルのみ）
- 開発元：有限会社シェルウェア（日本）

**機能**
- ✅ 検索順位チェック（Google、Yahoo、Bing）
- ❌ キーワード調査機能なし
- ❌ 収益管理機能なし
- ❌ コンテンツ分析なし

**料金プラン（年払い）**
| プラン | 料金 | サイト数 | キーワード数 |
|--------|------|----------|--------------|
| ベーシック | ¥4,950/年 | 5 | 500 |
| スタンダード | ¥9,900/年 | 50 | 5,000 |
| エキスパート | ¥14,850/年 | 500 | 50,000 |

**強み**
- ✅ 圧倒的なコストパフォーマンス
- ✅ 月払い対応（¥495/月～）
- ✅ シンプルで使いやすいUI
- ✅ 日本語完全対応

**弱み**
- ❌ Windows専用（Macユーザーは使えない）
- ❌ 機能が順位チェックのみ
- ❌ クラウド非対応（PCインストール型）
- ❌ スマホから確認不可

---

#### 2. Rank Tracker（高機能・海外製）

**概要**
- Link-Assistant.com社（海外）のSEOツール
- Mac・Windows対応
- 多機能・高機能

**機能**
- ✅ 検索順位チェック
- ✅ キーワード調査機能
- ✅ 競合分析機能
- ✅ SERP分析
- ❌ 収益管理機能なし

**料金プラン**
| プラン | 料金 | サイト数 | キーワード数 |
|--------|------|----------|--------------|
| Professional | $149/年（約¥21,000） | 無制限 | 無制限 |

**強み**
- ✅ Mac対応
- ✅ 多機能（キーワード調査、競合分析）
- ✅ サイト・キーワード数無制限

**弱み**
- ❌ 価格が高い（GRCの約4倍）
- ❌ 月払い不可（年払いのみ）
- ❌ 日本語UIが一部不完全
- ❌ 収益管理機能なし

---

#### 3. ミエルカSEO（国内エンタープライズ向け）

**概要**
- 株式会社Faber Company（日本）
- 大企業・代理店向けの統合型SEOツール

**機能**
- ✅ 検索順位チェック
- ✅ キーワード調査
- ✅ コンテンツSEO分析
- ✅ 競合分析
- ❌ 収益管理機能なし

**料金**
- 月額¥150,000～（要問い合わせ）
- 導入社数：1,900社

**強み**
- ✅ 包括的なSEO機能
- ✅ 日本語完全対応
- ✅ カスタマーサポート充実

**弱み**
- ❌ 価格が非常に高い（個人・副業向けではない）
- ❌ 個人アフィリエイター向けではない

---

### 競合比較マトリックス

| ツール | 価格帯 | 順位チェック | キーワード調査 | 収益管理 | Mac対応 | クラウド | ターゲット |
|--------|--------|--------------|----------------|----------|---------|----------|------------|
| **GRC** | ¥4,950/年 | ⭐⭐⭐⭐⭐ | ❌ | ❌ | ❌ | ❌ | 個人・中小 |
| **Rank Tracker** | ¥21,000/年 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ | ✅ | ❌ | 個人・中小 |
| **ミエルカSEO** | ¥150,000/月 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ | ✅ | ✅ | 大企業 |
| **RankFlow（あなたのツール）** | ¥980～/月 | ⭐⭐⭐⭐ | ❌（Phase2） | ⭐⭐⭐⭐⭐ | ✅ | ✅ | 個人アフィリエイター |

---

## 価格戦略とポジショニング

### ターゲット市場

**ペルソナ再定義**

**メインターゲット：副業アフィリエイター（市場規模推定：10万人）**
- 年齢：25～45歳
- 職業：会社員（副業）
- 運営サイト：1～3サイト
- 月間収益：1～10万円
- 課題：時間がない、複数ツールの管理が面倒、収益性の把握が困難

**サブターゲット：専業アフィリエイター初心者（市場規模推定：3万人）**
- 年齢：20～35歳
- 職業：フリーランス、専業
- 運営サイト：3～10サイト
- 月間収益：10～50万円
- 課題：効率化ツール不足、コスト意識高い

---

### 価格設定戦略

#### プライシングモデル：3層プラン

**1. Freeプラン（無料）**
```
料金：¥0/月
目的：トライアル・リード獲得

制限：
- サイト数：1サイト
- キーワード数：5キーワード
- 順位履歴：7日間
- 収益管理：1 ASP
- レポート：簡易版のみ

アップセル導線：
「もっとキーワードを追跡しませんか？」
「過去30日のデータを見るにはBasicプランへ」
```

**2. Basicプラン（メインターゲット）**
```
料金：¥980/月 または ¥9,800/年（2ヶ月分お得）
目的：メイン収益源

機能：
- サイト数：3サイト
- キーワード数：サイトあたり30キーワード
- 順位履歴：無制限
- 収益管理：無制限ASP
- 月次レポート：完全版
- メール通知：順位変動アラート

ターゲット：副業アフィリエイター
```

**3. Proプラン（専業向け）**
```
料金：¥2,980/月 または ¥29,800/年
目的：ヘビーユーザー・アップセル

機能：
- サイト数：10サイト
- キーワード数：サイトあたり100キーワード
- 順位履歴：無制限
- 収益管理：無制限ASP + 自動レポート
- 競合サイト分析（Phase 2）
- API連携（Phase 2）
- 優先サポート

ターゲット：専業アフィリエイター
```

---

### 競合比較とポジショニング

**価格比較（年間コスト）**
```
GRC ベーシック：     ¥4,950/年
RankFlow Basic：     ¥9,800/年  ← GRCの約2倍だが収益管理付き
Rank Tracker：       ¥21,000/年
ミエルカSEO：        ¥1,800,000/年
```

**ポジショニングマップ**
```
                    高機能
                      ↑
                      │
            Rank Tracker  ミエルカSEO
                      │
低価格 ←─────┼─────→ 高価格
        GRC   │  RankFlow
              │   (Basic)
              │
                    シンプル
                      ↓
```

**独自価値提案（UVP）**
> **「アフィリエイターのための、SEOと収益を一元管理するクラウドダッシュボード」**

---

## 差別化ポイントの明確化

### コア差別化要素

#### 1. アフィリエイト収益管理（最大の差別化）

**競合にない機能**
- SEO順位と収益を同一画面で確認
- ASP別の収益推移グラフ
- 記事別・キーワード別の収益性分析（Phase 2）

**ユーザー価値**
- 「どのキーワードが実際に稼いでいるか」が一目でわかる
- リライト優先度を収益ベースで判断できる
- 複数ASPの管理が一元化される

---

#### 2. クラウド・マルチデバイス対応

**競合との違い**
- GRC：Windowsインストール型、外出先で見れない
- Rank Tracker：PCインストール型、スマホ未対応
- **RankFlow：ブラウザでどこからでもアクセス可能**

**ユーザー価値**
- 通勤中にスマホで順位確認
- カフェでMacから編集
- データがクラウドに自動保存

---

#### 3. アフィリエイター特化のUI/UX

**設計思想**
- 「順位が上がったか？」「いくら稼いだか？」に最速でアクセス
- 初心者でも5分でセットアップ完了
- 日本のASP（A8.net、Amazonアソシエイト等）に最適化

**ユーザー価値**
- 学習コストゼロで即使える
- 日本のアフィリエイト市場に最適化

---

#### 4. 適正価格（GRCの2倍、Rank Trackerの半額以下）

**価格戦略**
```
GRC（¥4,950/年）：
- 順位チェックのみ
- Windows専用
- クラウド非対応

RankFlow Basic（¥9,800/年）：
- 順位チェック + 収益管理
- Mac/Windows/スマホ対応
- クラウド対応
→ GRCの2倍の価格だが、2倍以上の価値

Rank Tracker（¥21,000/年）：
- 多機能だが収益管理なし
- PCインストール型

RankFlow Basic（¥9,800/年）：
- アフィリエイターに必要な機能に絞る
→ Rank Trackerの半額以下
```

---

### マーケティングメッセージ

**トップページのキャッチコピー**
```
「順位チェックだけじゃない。
 アフィリエイターのための、
 SEO×収益管理ダッシュボード」

- 検索順位を毎日自動チェック
- 複数ASPの収益を一元管理
- Mac・Windows・スマホ対応
- 月額980円から

[今すぐ無料で始める]
```

**3つの特徴（LP）**
```
1. 📊 順位と収益を一画面で確認
   どのキーワードが本当に稼いでいるか、一目瞭然

2. 💻 どこからでもアクセス
   スマホでも、Macでも。クラウドだから場所を選ばない

3. 💰 適正価格
   月額980円。GRCより多機能、Rank Trackerより安い
```

---

# Part 3: 開発環境セットアップ

## Railsプロジェクト初期化

### 前提条件

**必要な環境**
```bash
# Ruby バージョン
ruby 3.2.2 以上

# Rails バージョン
rails 7.1.0 以上

# Node.js（Hotwire用）
node 18.x 以上

# PostgreSQL
postgresql 14.x 以上

# Redis（Sidekiq用）
redis 7.x 以上
```

---

### プロジェクト作成手順

#### Step 1: Railsアプリケーション作成

```bash
# プロジェクト作成（PostgreSQL使用、Hotwireデフォルト）
rails new rankflow \
  --database=postgresql \
  --css=tailwind \
  --javascript=hotwire

cd rankflow
```

**オプション説明**
- `--database=postgresql`：本番環境と同じDB
- `--css=tailwind`：Tailwind CSS使用
- `--javascript=hotwire`：Turbo + Stimulus使用

---

#### Step 2: データベース作成

```bash
# database.ymlの設定確認
cat config/database.yml

# データベース作成
rails db:create

# 確認
rails db:version
```

**`config/database.yml`（開発環境）**
```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: rankflow_development

test:
  <<: *default
  database: rankflow_test

production:
  <<: *default
  database: rankflow_production
  username: rankflow
  password: <%= ENV['RANKFLOW_DATABASE_PASSWORD'] %>
```

---

#### Step 3: Gitリポジトリ初期化

```bash
# Git初期化
git init

# .gitignoreに追加
echo "/config/master.key" >> .gitignore
echo ".env" >> .gitignore

# 初回コミット
git add .
git commit -m "Initial commit: Rails 7.1 with Hotwire"

# GitHubリポジトリ作成（事前にGitHubで作成）
git remote add origin git@github.com:yourusername/rankflow.git
git branch -M main
git push -u origin main
```

---

## 必須Gem・ライブラリ構成

### Gemfile編集

**`Gemfile`**
```ruby
source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

# Core
gem "rails", "~> 7.1.0"
gem "pg", "~> 1.5"
gem "puma", "~> 6.4"

# Frontend
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 2.0"
gem "view_component", "~> 3.9"

# Authentication
gem "devise", "~> 4.9"

# Background Jobs
gem "sidekiq", "~> 7.2"
gem "sidekiq-cron", "~> 1.11"  # スケジュール実行

# API Integration
gem "google-apis-customsearch_v1", "~> 0.14"  # Google Custom Search API
gem "faraday", "~> 2.8"  # HTTPクライアント

# Utilities
gem "dotenv-rails", groups: [:development, :test]  # 環境変数管理
gem "kaminari", "~> 1.2"  # ページネーション
gem "chartkick", "~> 5.0"  # グラフ表示

# Performance
gem "bootsnap", require: false
gem "redis", "~> 5.0"

# Monitoring & Error Tracking（本番のみ）
gem "sentry-ruby", "~> 5.15"
gem "sentry-rails", "~> 5.15"

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
end

group :development do
  gem "web-console"
  gem "annotate", "~> 3.2"  # スキーマ注釈
  gem "bullet", "~> 7.1"  # N+1クエリ検出
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
```

---

### Gemインストール

```bash
# Gemインストール
bundle install

# Tailwind CSSビルド設定
rails tailwindcss:install

# Deviseインストール
rails generate devise:install
rails generate devise User

# RSpecインストール（テスト環境）
rails generate rspec:install

# ViewComponentインストール
rails generate view_component:install
```

---

## Herokuデプロイ設定

### Heroku初期設定

#### Step 1: Heroku CLIインストール

```bash
# Heroku CLIインストール確認
heroku --version

# ログイン
heroku login
```

---

#### Step 2: Herokuアプリ作成

```bash
# アプリ作成
heroku create rankflow-mvp

# PostgreSQLアドオン追加（無料プラン）
heroku addons:create heroku-postgresql:mini

# Redisアドオン追加（Sidekiq用）
heroku addons:create heroku-redis:mini

# 確認
heroku addons
```

---

#### Step 3: 環境変数設定

```bash
# Rails マスターキー設定
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)

# Google Custom Search API設定
heroku config:set GOOGLE_API_KEY=your_api_key_here
heroku config:set GOOGLE_SEARCH_ENGINE_ID=your_cx_id_here

# 確認
heroku config
```

---

#### Step 4: Procfile作成

**`Procfile`（Heroku起動設定）**
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
release: bundle exec rails db:migrate
```

**説明**
- `web`：Pumaサーバー起動
- `worker`：Sidekiqワーカー起動（バックグラウンドジョブ）
- `release`：デプロイ時に自動マイグレーション実行

---

#### Step 5: デプロイ

```bash
# 初回デプロイ
git add .
git commit -m "Add Heroku configuration"
git push heroku main

# デプロイ確認
heroku logs --tail

# ブラウザで開く
heroku open
```

---

### Heroku運用設定

#### Sidekiqワーカー起動

```bash
# Workerプロセス有効化（有料Dyno必要）
heroku ps:scale worker=1

# 確認
heroku ps
```

**料金**
- Web Dyno（Basic）：$7/月
- Worker Dyno（Basic）：$7/月
- PostgreSQL Mini：$5/月
- Redis Mini：無料
- **合計：約$19/月（¥2,500～）**

---

#### 定期ジョブ設定（順位チェック）

**`config/sidekiq.yml`**
```yaml
:concurrency: 5
:queues:
  - default
  - mailers

:schedule:
  daily_rank_check:
    cron: '0 2 * * *'  # 毎日午前2時（JST: 11:00）
    class: DailyRankCheckJob
    queue: default
```

---

# Part 4: 技術実装詳細設計

## データベース詳細設計

### ER図（Entity Relationship Diagram）

```
┌─────────────┐
│   users     │
├─────────────┤
│ id          │──┐
│ email       │  │
│ password    │  │
│ name        │  │
│ plan        │  │  1:N
│ created_at  │  │
│ updated_at  │  │
└─────────────┘  │
                 │
                 ↓
┌─────────────┐  │
│   sites     │  │
├─────────────┤  │
│ id          │←─┘
│ user_id (FK)│──┐
│ name        │  │
│ url         │  │
│ description │  │  1:N
│ created_at  │  │
│ updated_at  │  │
└─────────────┘  │
                 │
        ┌────────┴────────┐
        ↓                 ↓
┌─────────────┐   ┌─────────────┐
│  keywords   │   │  revenues   │
├─────────────┤   ├─────────────┤
│ id          │   │ id          │
│ site_id (FK)│   │ site_id (FK)│
│ word        │──┐│ asp_name    │
│ target_url  │  ││ amount      │
│ created_at  │  ││ month       │
│ updated_at  │  ││ created_at  │
└─────────────┘  ││ updated_at  │
                 │└─────────────┘
                 │ 1:N
                 ↓
┌──────────────────┐
│ rank_histories   │
├──────────────────┤
│ id               │
│ keyword_id (FK)  │
│ rank             │
│ checked_at       │
│ created_at       │
└──────────────────┘
```

---

### マイグレーションファイル

#### 1. Usersテーブル（Deviseで自動生成）

```ruby
# db/migrate/20260201000001_devise_create_users.rb
class DeviseCreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      # Devise標準フィールド
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      
      # 追加フィールド
      t.string :name, null: false
      t.string :plan, null: false, default: "free"  # free, basic, pro
      
      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
```

---

#### 2. Sitesテーブル

```ruby
# db/migrate/20260201000002_create_sites.rb
class CreateSites < ActiveRecord::Migration[7.1]
  def change
    create_table :sites do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :url, null: false
      t.text :description
      
      t.timestamps
    end
    
    add_index :sites, [:user_id, :created_at]
  end
end
```

---

#### 3. Keywordsテーブル

```ruby
# db/migrate/20260201000003_create_keywords.rb
class CreateKeywords < ActiveRecord::Migration[7.1]
  def change
    create_table :keywords do |t|
      t.references :site, null: false, foreign_key: true
      t.string :word, null: false
      t.string :target_url
      
      t.timestamps
    end
    
    add_index :keywords, [:site_id, :word], unique: true
    add_index :keywords, :created_at
  end
end
```

---

#### 4. RankHistoriesテーブル

```ruby
# db/migrate/20260201000004_create_rank_histories.rb
class CreateRankHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :rank_histories do |t|
      t.references :keyword, null: false, foreign_key: true
      t.integer :rank, null: false  # 101 = 圏外
      t.date :checked_at, null: false
      
      t.timestamps
    end
    
    add_index :rank_histories, [:keyword_id, :checked_at], unique: true
    add_index :rank_histories, :checked_at
  end
end
```

---

#### 5. Revenuesテーブル

```ruby
# db/migrate/20260201000005_create_revenues.rb
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
    add_index :revenues, :month
  end
end
```

---

### モデル実装

#### User Model

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_many :sites, dependent: :destroy
  
  validates :name, presence: true
  validates :plan, inclusion: { in: %w[free basic pro] }
  
  # プラン別制限
  def max_sites
    case plan
    when 'free' then 1
    when 'basic' then 3
    when 'pro' then 10
    end
  end
  
  def max_keywords_per_site
    case plan
    when 'free' then 5
    when 'basic' then 30
    when 'pro' then 100
    end
  end
end
```

---

#### Site Model

```ruby
# app/models/site.rb
class Site < ApplicationRecord
  belongs_to :user
  has_many :keywords, dependent: :destroy
  has_many :revenues, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 100 }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
  validates :description, length: { maximum: 500 }
  
  # 平均順位を計算
  def average_rank(date = Date.today)
    keywords.joins(:rank_histories)
            .where(rank_histories: { checked_at: date })
            .where('rank_histories.rank <= 100')  # 圏外除外
            .average('rank_histories.rank')
            .to_f
            .round(1)
  end
  
  # 月次収益合計
  def total_revenue(month = Date.today.beginning_of_month)
    revenues.where(month: month).sum(:amount)
  end
end
```

---

#### Keyword Model

```ruby
# app/models/keyword.rb
class Keyword < ApplicationRecord
  belongs_to :site
  has_many :rank_histories, dependent: :destroy
  
  validates :word, presence: true, length: { maximum: 100 }
  validates :word, uniqueness: { scope: :site_id }
  validates :target_url, format: { with: URI::DEFAULT_PARSER.make_regexp }, allow_blank: true
  
  # 最新順位
  def current_rank
    rank_histories.order(checked_at: :desc).first&.rank || 101
  end
  
  # 前日比
  def rank_change
    today_rank = rank_histories.find_by(checked_at: Date.today)&.rank
    yesterday_rank = rank_histories.find_by(checked_at: Date.yesterday)&.rank
    
    return nil unless today_rank && yesterday_rank
    
    yesterday_rank - today_rank  # 正の値 = 順位UP
  end
  
  # 30日間の履歴
  def rank_history_30days
    rank_histories.where('checked_at >= ?', 30.days.ago)
                  .order(checked_at: :asc)
  end
end
```

---

#### RankHistory Model

```ruby
# app/models/rank_history.rb
class RankHistory < ApplicationRecord
  belongs_to :keyword
  
  validates :rank, presence: true, numericality: { 
    only_integer: true, 
    greater_than_or_equal_to: 1, 
    less_than_or_equal_to: 101 
  }
  validates :checked_at, presence: true
  validates :checked_at, uniqueness: { scope: :keyword_id }
  
  scope :ranked, -> { where('rank <= 100') }  # 圏外除外
  scope :recent, -> { order(checked_at: :desc) }
end
```

---

#### Revenue Model

```ruby
# app/models/revenue.rb
class Revenue < ApplicationRecord
  belongs_to :site
  
  validates :asp_name, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :month, presence: true
  validates :month, uniqueness: { scope: [:site_id, :asp_name] }
  
  scope :by_month, ->(month) { where(month: month) }
  scope :recent_6months, -> { where('month >= ?', 6.months.ago.beginning_of_month) }
end
```

---

## Google Custom Search API実装

### API設定手順

#### Step 1: Google Cloud Consoleでプロジェクト作成

1. https://console.cloud.google.com/ にアクセス
2. 新規プロジェクト作成「RankFlow」
3. APIとサービス → ライブラリ → 「Custom Search API」を有効化
4. 認証情報 → APIキー作成
5. APIキーをコピー → `GOOGLE_API_KEY`

---

#### Step 2: Custom Search Engine作成

1. https://programmablesearchengine.google.com/ にアクセス
2. 「追加」をクリック
3. 設定：
   - 検索するサイト：「ウェブ全体を検索」
   - 検索エンジン名：「RankFlow Search」
4. 作成後、「検索エンジンID（cx）」をコピー → `GOOGLE_SEARCH_ENGINE_ID`

---

### サービスクラス実装

**`app/services/rank_checker_service.rb`**
```ruby
require 'google/apis/customsearch_v1'

class RankCheckerService
  MAX_RESULTS = 100  # 100位まで取得
  RESULTS_PER_PAGE = 10
  
  def initialize(keyword_word, site_url)
    @keyword_word = keyword_word
    @site_url = normalize_url(site_url)
    @client = Google::Apis::CustomsearchV1::CustomSearchAPIService.new
    @client.key = ENV['GOOGLE_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_ENGINE_ID']
  end
  
  def check_rank
    (1..10).each do |page|  # 100位まで（10ページ）
      start_index = (page - 1) * RESULTS_PER_PAGE + 1
      
      results = fetch_search_results(start_index)
      rank = find_rank_in_results(results, start_index - 1)
      
      return rank if rank
      
      sleep 1  # API制限対策
    end
    
    101  # 100位圏外
  rescue Google::Apis::Error => e
    Rails.logger.error("Google API Error: #{e.message}")
    nil  # エラー時はnilを返す
  end
  
  private
  
  def fetch_search_results(start_index)
    @client.list_cses(
      q: @keyword_word,
      cx: @cx,
      num: RESULTS_PER_PAGE,
      start: start_index,
      gl: 'jp',  # 日本の検索結果
      lr: 'lang_ja'  # 日本語
    )
  end
  
  def find_rank_in_results(results, offset)
    return nil unless results&.items
    
    results.items.each_with_index do |item, index|
      item_url = normalize_url(item.link)
      
      if item_url.include?(@site_url) || @site_url.include?(item_url)
        return offset + index + 1
      end
    end
    
    nil
  end
  
  def normalize_url(url)
    # URLを正規化（http/https、www有無、末尾スラッシュを統一）
    url = url.to_s.downcase
    url = url.gsub(/^https?:\/\/(www\.)?/, '')
    url = url.gsub(/\/$/, '')
    url
  end
end
```

---

### 使用例

```ruby
# コントローラーやジョブから呼び出し
keyword = Keyword.find(1)
service = RankCheckerService.new(keyword.word, keyword.site.url)
rank = service.check_rank

if rank
  keyword.rank_histories.create!(
    rank: rank,
    checked_at: Date.today
  )
end
```

---

## バックグラウンドジョブ設計

### Sidekiq設定

**`config/sidekiq.yml`**
```yaml
:concurrency: 5
:max_retries: 3
:queues:
  - default
  - mailers

:schedule:
  # 毎日午前2時に全キーワードの順位チェック
  daily_rank_check:
    cron: '0 2 * * *'  # UTC 2:00 = JST 11:00
    class: DailyRankCheckJob
    queue: default
```

---

### ジョブ実装

**`app/jobs/daily_rank_check_job.rb`**
```ruby
class DailyRankCheckJob < ApplicationJob
  queue_as :default
  
  def perform
    total_keywords = Keyword.count
    processed = 0
    
    Keyword.includes(:site).find_each do |keyword|
      RankCheckWorkerJob.perform_later(keyword.id)
      processed += 1
      
      # 進捗ログ
      if processed % 10 == 0
        Rails.logger.info("Rank check progress: #{processed}/#{total_keywords}")
      end
      
      sleep 1  # API制限対策（1秒間隔）
    end
    
    Rails.logger.info("Daily rank check completed: #{processed} keywords")
  end
end
```

---

**`app/jobs/rank_check_worker_job.rb`**
```ruby
class RankCheckWorkerJob < ApplicationJob
  queue_as :default
  retry_on Google::Apis::Error, wait: 5.minutes, attempts: 3
  
  def perform(keyword_id)
    keyword = Keyword.find(keyword_id)
    
    # 既に今日の順位を取得済みならスキップ
    return if keyword.rank_histories.exists?(checked_at: Date.today)
    
    rank = RankCheckerService.new(keyword.word, keyword.site.url).check_rank
    
    if rank
      keyword.rank_histories.create!(
        rank: rank,
        checked_at: Date.today
      )
      
      # 大きな変動があればメール通知（Phase 2）
      notify_if_significant_change(keyword, rank)
    else
      Rails.logger.error("Failed to check rank for keyword: #{keyword.id}")
    end
  end
  
  private
  
  def notify_if_significant_change(keyword, current_rank)
    yesterday_rank = keyword.rank_histories.find_by(checked_at: Date.yesterday)&.rank
    return unless yesterday_rank
    
    change = yesterday_rank - current_rank
    
    # ±5位以上の変動でメール送信
    if change.abs >= 5
      RankChangeMailer.significant_change(keyword, current_rank, change).deliver_later
    end
  end
end
```

---

### ローカル開発でのSidekiq起動

```bash
# Redisサーバー起動（別ターミナル）
redis-server

# Sidekiqワーカー起動（別ターミナル）
bundle exec sidekiq

# Railsサーバー起動
rails server
```

---

## 次のステップ

この包括的開発ガイドで、以下をカバーしました：

✅ **Part 1: UI/UX設計**
- デザインシステム・カラーパレット
- ユーザーフロー図
- 全画面のワイヤーフレーム

✅ **Part 2: 競合分析**
- GRC・Rank Tracker・ミエルカSEO詳細比較
- 3層価格戦略（Free/Basic/Pro）
- 4つの差別化ポイント明確化

✅ **Part 3: 開発環境**
- Railsプロジェクト初期化手順
- 必須Gem構成
- Herokuデプロイ完全ガイド

✅ **Part 4: 技術実装**
- 完全なデータベース設計
- Google Custom Search API実装
- Sidekiqバックグラウンドジョブ設計

---

### 実際の開発開始に向けて

**今すぐできること：**

1. **環境構築**
   ```bash
   rails new rankflow --database=postgresql --css=tailwind --javascript=hotwire
   cd rankflow
   bundle install
   rails db:create
   ```

2. **Google API設定**
   - Google Cloud Consoleでプロジェクト作成
   - Custom Search API有効化
   - 検索エンジンID取得

3. **Herokuアカウント作成**
   - https://signup.heroku.com/
   - クレジットカード登録（無料枠利用も要登録）

4. **開発開始**
   - Week 1-2: 認証・基盤機能
   - Week 3-4: 順位チェック機能
   - Week 5-6: ダッシュボード・収益管理
   - Week 7-8: テスト・デプロイ

---

何か質問や、特定の部分をさらに深掘りしたい箇所はありますか？
