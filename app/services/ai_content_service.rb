# frozen_string_literal: true

class AiContentService
  class ApiError < StandardError; end

  def initialize
    @client = OpenAI::Client.new
  end

  def generate_title_suggestions(keyword:, current_title: nil, count: 5)
    prompt = build_title_prompt(keyword, current_title, count)
    response = chat_completion(prompt)
    parse_list_response(response)
  rescue StandardError => e
    Rails.logger.error("AI Title Generation Error: #{e.message}")
    mock_title_suggestions(keyword, count)
  end

  def generate_outline(keyword:, title:)
    prompt = build_outline_prompt(keyword, title)
    response = chat_completion(prompt)
    parse_outline_response(response)
  rescue StandardError => e
    Rails.logger.error("AI Outline Generation Error: #{e.message}")
    mock_outline(keyword, title)
  end

  def generate_rewrite_suggestions(article:, keywords:)
    prompt = build_rewrite_prompt(article, keywords)
    response = chat_completion(prompt)
    parse_rewrite_response(response)
  rescue StandardError => e
    Rails.logger.error("AI Rewrite Suggestion Error: #{e.message}")
    mock_rewrite_suggestions(article, keywords)
  end

  def improve_meta_description(keyword:, current_description: nil)
    prompt = build_meta_description_prompt(keyword, current_description)
    response = chat_completion(prompt)
    response.strip
  rescue StandardError => e
    Rails.logger.error("AI Meta Description Error: #{e.message}")
    mock_meta_description(keyword)
  end

  private

  def chat_completion(prompt, model: "gpt-3.5-turbo")
    return mock_response(prompt) unless api_configured?

    response = @client.chat(
      parameters: {
        model: model,
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: prompt }
        ],
        temperature: 0.7,
        max_tokens: 1000
      }
    )

    if response["error"]
      raise ApiError, response["error"]["message"]
    end

    response.dig("choices", 0, "message", "content") || ""
  end

  def api_configured?
    ENV["OPENAI_API_KEY"].present?
  end

  def system_prompt
    <<~PROMPT
      You are an expert SEO content strategist specializing in Japanese affiliate marketing content.
      Your responses should be:
      - Written in Japanese
      - SEO-optimized
      - Engaging and click-worthy
      - Following best practices for search engine rankings
    PROMPT
  end

  def build_title_prompt(keyword, current_title, count)
    <<~PROMPT
      Generate #{count} SEO-optimized article titles for the keyword "#{keyword}".
      #{current_title ? "Current title: #{current_title}" : ""}

      Requirements:
      - Each title should be unique and engaging
      - Include the main keyword naturally
      - Keep titles between 30-60 characters
      - Use power words and numbers when appropriate
      - Make titles click-worthy while being accurate

      Format: Return only the titles, one per line, numbered 1-#{count}.
    PROMPT
  end

  def build_outline_prompt(keyword, title)
    <<~PROMPT
      Create a detailed article outline for:
      Title: "#{title}"
      Target Keyword: "#{keyword}"

      Requirements:
      - Include H2 and H3 headings
      - Cover the topic comprehensively
      - Include sections that address user intent
      - Suggest where to place affiliate links naturally
      - Aim for 10-15 sections total

      Format: Return as a structured outline with H2: and H3: prefixes.
    PROMPT
  end

  def build_rewrite_prompt(article, keywords)
    keyword_info = keywords.map do |k|
      "#{k.word}: Current rank #{k.current_rank || 'N/A'}, Change: #{k.rank_change || 'N/A'}"
    end.join("\n")

    <<~PROMPT
      Analyze this article and provide specific rewrite recommendations:

      Article Title: "#{article.title}"
      Article URL: #{article.url}

      Associated Keywords Performance:
      #{keyword_info}

      Provide:
      1. Analysis of why rankings may have dropped
      2. 5 specific content improvements
      3. SEO optimization suggestions
      4. Internal linking opportunities
      5. Content freshness recommendations

      Format each section clearly with headers.
    PROMPT
  end

  def build_meta_description_prompt(keyword, current_description)
    <<~PROMPT
      Generate an SEO-optimized meta description for the keyword "#{keyword}".
      #{current_description ? "Current description: #{current_description}" : ""}

      Requirements:
      - 120-155 characters
      - Include the keyword naturally
      - Include a call to action
      - Be compelling and accurate

      Return only the meta description text.
    PROMPT
  end

  def parse_list_response(response)
    response.split("\n")
            .map { |line| line.gsub(/^\d+[\.\)]\s*/, "").strip }
            .reject(&:blank?)
  end

  def parse_outline_response(response)
    sections = []
    current_h2 = nil

    response.split("\n").each do |line|
      line = line.strip
      next if line.blank?

      if line.start_with?("H2:", "##")
        current_h2 = {
          type: "h2",
          title: line.gsub(/^(H2:|##)\s*/, "").strip,
          children: []
        }
        sections << current_h2
      elsif line.start_with?("H3:", "###") && current_h2
        current_h2[:children] << {
          type: "h3",
          title: line.gsub(/^(H3:|###)\s*/, "").strip
        }
      end
    end

    sections
  end

  def parse_rewrite_response(response)
    {
      raw: response,
      sections: response.split(/\n(?=\d+\.|##)/).map(&:strip).reject(&:blank?)
    }
  end

  # Mock responses when API is not configured
  def mock_response(prompt)
    "AI response mock - API key not configured"
  end

  def mock_title_suggestions(keyword, count)
    [
      "【2024年最新】#{keyword}の完全ガイド",
      "#{keyword}のおすすめ#{rand(5..10)}選｜プロが厳選",
      "#{keyword}とは？初心者向けに徹底解説",
      "【比較】#{keyword}の選び方と注意点",
      "#{keyword}で失敗しないための#{rand(3..7)}つのポイント"
    ].first(count)
  end

  def mock_outline(keyword, title)
    [
      { type: "h2", title: "#{keyword}とは？基本を解説", children: [
        { type: "h3", title: "#{keyword}の定義" },
        { type: "h3", title: "#{keyword}が注目される理由" }
      ] },
      { type: "h2", title: "#{keyword}のメリット・デメリット", children: [
        { type: "h3", title: "メリット#{rand(3..5)}選" },
        { type: "h3", title: "デメリットと注意点" }
      ] },
      { type: "h2", title: "#{keyword}の選び方", children: [
        { type: "h3", title: "選ぶ際のポイント" },
        { type: "h3", title: "おすすめの比較方法" }
      ] },
      { type: "h2", title: "#{keyword}のおすすめランキング", children: [
        { type: "h3", title: "第1位：○○○" },
        { type: "h3", title: "第2位：○○○" },
        { type: "h3", title: "第3位：○○○" }
      ] },
      { type: "h2", title: "まとめ", children: [] }
    ]
  end

  def mock_rewrite_suggestions(article, keywords)
    {
      raw: <<~TEXT,
        ## 分析結果

        #{article.title}の順位改善のための提案です。

        ### 1. コンテンツの更新
        - 最新情報の追加を検討してください
        - 統計データを更新してください

        ### 2. SEO最適化
        - タイトルタグの最適化
        - 見出し構造の改善
        - 内部リンクの追加

        ### 3. ユーザー体験の向上
        - 画像の追加
        - 表やリストの活用
        - CTAの改善
      TEXT
      sections: [
        "コンテンツの更新が必要です",
        "SEO最適化を行ってください",
        "ユーザー体験を向上させましょう"
      ]
    }
  end

  def mock_meta_description(keyword)
    "#{keyword}について徹底解説。選び方やおすすめを紹介します。この記事を読めば#{keyword}の全てがわかります。"
  end
end
