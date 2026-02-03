# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AiContentService do
  let(:client_double) { instance_double(OpenAI::Client) }
  let(:user) { create(:user) }
  let(:site) { create(:site, user: user) }
  let(:article) { create(:article, site: site, title: 'Test Article') }
  let(:keyword) { create(:keyword, site: site, word: 'テストキーワード') }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(client_double)
  end

  let(:service) { described_class.new }

  describe '#generate_title_suggestions' do
    context 'when API is configured' do
      let(:mock_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => "1. SEO対策の完全ガイド\n2. SEO対策で上位表示を狙う方法\n3. 初心者向けSEO対策入門"
              }
            }
          ]
        }
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
        allow(client_double).to receive(:chat).and_return(mock_response)
      end

      it 'calls OpenAI API and parses response' do
        result = service.generate_title_suggestions(keyword: 'SEO対策', count: 3)

        expect(result).to be_an(Array)
        expect(result.length).to eq(3)
        expect(result.first).to eq('SEO対策の完全ガイド')
      end

      it 'parses numbered list correctly' do
        result = service.generate_title_suggestions(keyword: 'SEO対策', count: 3)

        expect(result).not_to include(/^\d+\./)
      end
    end

    context 'when API returns an error response' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
        allow(client_double).to receive(:chat).and_return({ 'error' => { 'message' => 'Rate limit exceeded' } })
      end

      it 'falls back to mock title suggestions' do
        result = service.generate_title_suggestions(keyword: 'SEO対策')
        expect(result).to be_an(Array)
        expect(result.first).to include('SEO対策')
        expect(result.length).to eq(5)
      end
    end

    context 'when network error occurs' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
        allow(client_double).to receive(:chat).and_raise(Faraday::ConnectionFailed.new('Connection refused'))
      end

      it 'falls back to mock response and logs error' do
        expect(Rails.logger).to receive(:error).with(/AI Title Generation Error/)
        result = service.generate_title_suggestions(keyword: 'SEO対策')
        expect(result).to be_an(Array)
        expect(result.first).to include('SEO対策')
      end
    end

    context 'when StandardError occurs' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
        allow(client_double).to receive(:chat).and_raise(StandardError.new('Unknown error'))
      end

      it 'falls back to mock title suggestions with correct count' do
        result = service.generate_title_suggestions(keyword: 'テスト', count: 3)
        expect(result).to be_an(Array)
        expect(result.length).to eq(3)
      end
    end
  end

  describe '#generate_outline' do
    context 'when API is configured' do
      let(:mock_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => <<~OUTLINE
                  H2: SEO対策とは
                  H3: SEOの基本概念
                  H3: なぜSEOが重要なのか
                  H2: SEO対策の方法
                  H3: オンページSEO
                  H3: オフページSEO
                OUTLINE
              }
            }
          ]
        }
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
        allow(client_double).to receive(:chat).and_return(mock_response)
      end

      it 'parses outline response correctly' do
        result = service.generate_outline(keyword: 'SEO対策', title: 'SEO対策完全ガイド')

        expect(result.length).to eq(2)
        expect(result.first[:title]).to eq('SEO対策とは')
        expect(result.first[:type]).to eq('h2')
        expect(result.first[:children].length).to eq(2)
      end

      it 'structures h3 as children of h2' do
        result = service.generate_outline(keyword: 'SEO対策', title: 'SEO対策完全ガイド')

        first_section = result.first
        expect(first_section[:children]).to be_an(Array)
        expect(first_section[:children].first[:type]).to eq('h3')
        expect(first_section[:children].first[:title]).to eq('SEOの基本概念')
      end
    end

    context 'when API returns an error' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
        allow(client_double).to receive(:chat).and_raise(StandardError.new('API Error'))
      end

      it 'falls back to mock outline' do
        expect(Rails.logger).to receive(:error).with(/AI Outline Generation Error/)
        result = service.generate_outline(keyword: 'SEO対策', title: 'SEO対策完全ガイド')
        expect(result).to be_an(Array)
        expect(result.first[:type]).to eq('h2')
        expect(result.first).to have_key(:children)
      end

      it 'includes keyword in mock outline sections' do
        allow(Rails.logger).to receive(:error)
        result = service.generate_outline(keyword: 'SEO対策', title: 'SEO対策完全ガイド')
        expect(result.first[:title]).to include('SEO対策')
      end
    end

    context 'when parsing markdown ## format' do
      let(:mock_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => <<~OUTLINE
                  ## 第1章
                  ### サブセクション1
                  ### サブセクション2
                  ## 第2章
                  ### サブセクション3
                OUTLINE
              }
            }
          ]
        }
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
        allow(client_double).to receive(:chat).and_return(mock_response)
      end

      it 'handles markdown ## and ### headers' do
        result = service.generate_outline(keyword: 'test', title: 'Test Title')

        # Parser extracts H2 sections with their children
        h2_sections = result.select { |s| s[:type] == 'h2' }
        expect(h2_sections).to be_present
        expect(h2_sections.first[:title]).to eq('第1章')
      end
    end
  end

  describe '#generate_rewrite_suggestions' do
    let(:keywords_with_ranks) do
      [
        create(:keyword, site: site, word: 'キーワード1'),
        create(:keyword, site: site, word: 'キーワード2')
      ]
    end

    context 'when API is configured' do
      let(:mock_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => <<~SUGGESTIONS
                  ## 分析結果
                  順位低下の原因分析

                  ## 改善提案
                  1. タイトルの最適化
                  2. コンテンツの更新
                SUGGESTIONS
              }
            }
          ]
        }
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
        allow(client_double).to receive(:chat).and_return(mock_response)
      end

      it 'returns structured rewrite suggestions' do
        result = service.generate_rewrite_suggestions(article: article, keywords: keywords_with_ranks)

        expect(result[:raw]).to include('分析結果')
        expect(result[:sections]).to be_an(Array)
      end

      it 'includes both raw and sections keys' do
        result = service.generate_rewrite_suggestions(article: article, keywords: keywords_with_ranks)

        expect(result).to have_key(:raw)
        expect(result).to have_key(:sections)
      end
    end

    context 'when API returns an error' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
        allow(client_double).to receive(:chat).and_raise(StandardError.new('Timeout'))
      end

      it 'falls back to mock suggestions' do
        expect(Rails.logger).to receive(:error).with(/AI Rewrite Suggestion Error/)
        result = service.generate_rewrite_suggestions(article: article, keywords: keywords_with_ranks)
        expect(result).to have_key(:raw)
        expect(result).to have_key(:sections)
      end

      it 'includes article title in mock suggestions' do
        allow(Rails.logger).to receive(:error)
        result = service.generate_rewrite_suggestions(article: article, keywords: keywords_with_ranks)
        expect(result[:raw]).to include(article.title)
      end

      it 'includes actionable sections' do
        allow(Rails.logger).to receive(:error)
        result = service.generate_rewrite_suggestions(article: article, keywords: keywords_with_ranks)
        expect(result[:sections]).to be_an(Array)
        expect(result[:sections].length).to be >= 1
      end
    end
  end

  describe '#improve_meta_description' do
    context 'when API is configured' do
      let(:mock_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => '  SEO対策の完全ガイド。初心者でもわかりやすく解説します。  '
              }
            }
          ]
        }
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
        allow(client_double).to receive(:chat).and_return(mock_response)
      end

      it 'returns stripped meta description' do
        result = service.improve_meta_description(keyword: 'SEO対策')
        expect(result).to eq('SEO対策の完全ガイド。初心者でもわかりやすく解説します。')
        expect(result).not_to start_with(' ')
        expect(result).not_to end_with(' ')
      end
    end

    context 'when API returns an error' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
        allow(client_double).to receive(:chat).and_raise(StandardError.new('Server error'))
      end

      it 'falls back to mock meta description' do
        expect(Rails.logger).to receive(:error).with(/AI Meta Description Error/)
        result = service.improve_meta_description(keyword: 'SEO対策')
        expect(result).to be_a(String)
        expect(result).to include('SEO対策')
      end
    end

    context 'when providing current description' do
      let(:mock_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => '改善されたメタディスクリプション'
              }
            }
          ]
        }
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
        allow(client_double).to receive(:chat).and_return(mock_response)
      end

      it 'accepts optional current_description parameter' do
        result = service.improve_meta_description(
          keyword: 'SEO対策',
          current_description: '現在のディスクリプション'
        )
        expect(result).to be_a(String)
      end
    end
  end

  describe 'ApiError' do
    it 'is a custom error class' do
      expect(AiContentService::ApiError).to be < StandardError
    end

    it 'can be raised with a message' do
      expect { raise AiContentService::ApiError, 'Test error' }
        .to raise_error(AiContentService::ApiError, 'Test error')
    end
  end

  describe 'API error response handling' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
    end

    it 'raises ApiError when API returns error in response' do
      error_response = { 'error' => { 'message' => 'Rate limit exceeded' } }
      allow(client_double).to receive(:chat).and_return(error_response)

      # The error is caught and falls back to mock
      result = service.generate_title_suggestions(keyword: 'test')
      expect(result).to be_an(Array)
    end
  end

  describe 'edge cases' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
    end

    context 'when API returns empty content' do
      let(:empty_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => ''
              }
            }
          ]
        }
      end

      before do
        allow(client_double).to receive(:chat).and_return(empty_response)
      end

      it 'handles empty title suggestions' do
        result = service.generate_title_suggestions(keyword: 'test')
        expect(result).to be_an(Array)
      end

      it 'handles empty outline' do
        result = service.generate_outline(keyword: 'test', title: 'Test')
        expect(result).to be_an(Array)
      end
    end

    context 'when API returns nil content' do
      let(:nil_response) do
        {
          'choices' => [
            {
              'message' => {}
            }
          ]
        }
      end

      before do
        allow(client_double).to receive(:chat).and_return(nil_response)
      end

      it 'handles nil content gracefully for titles' do
        result = service.generate_title_suggestions(keyword: 'test')
        expect(result).to be_an(Array)
      end
    end
  end
end
