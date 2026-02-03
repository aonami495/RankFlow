# frozen_string_literal: true

require "rails_helper"

RSpec.describe RankCheckerService do
  let(:keyword_word) { "SEO対策" }
  let(:site_url) { "https://example.com" }
  let(:service) { described_class.new(keyword_word, site_url) }

  describe RankCheckerService::Result do
    describe "#success?" do
      it "returns true for success status" do
        result = described_class.new(rank: 5, status: :success)
        expect(result.success?).to be true
      end

      it "returns false for error status" do
        result = described_class.new(status: :api_error)
        expect(result.success?).to be false
      end
    end

    describe "#failed?" do
      it "returns false for success status" do
        result = described_class.new(rank: 5, status: :success)
        expect(result.failed?).to be false
      end

      it "returns true for error status" do
        result = described_class.new(status: :rate_limited)
        expect(result.failed?).to be true
      end
    end

    describe "#rate_limited?" do
      it "returns true for rate_limited status" do
        result = described_class.new(status: :rate_limited)
        expect(result.rate_limited?).to be true
      end

      it "returns false for other statuses" do
        result = described_class.new(status: :success)
        expect(result.rate_limited?).to be false
      end
    end
  end

  describe "#initialize" do
    it "normalizes the site URL" do
      service1 = described_class.new("test", "https://www.example.com/")
      service2 = described_class.new("test", "http://example.com")
      service3 = described_class.new("test", "HTTPS://EXAMPLE.COM/")

      expect(service1.send(:normalize_url, "https://www.example.com/")).to eq("example.com")
      expect(service2.send(:normalize_url, "http://example.com")).to eq("example.com")
      expect(service3.send(:normalize_url, "HTTPS://EXAMPLE.COM/")).to eq("example.com")
    end
  end

  describe "#execute" do
    context "when API key is not configured" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("SERPAPI_KEY").and_return(nil)
      end

      it "returns nil" do
        result = service.execute
        expect(result).to be_nil
      end
    end

    context "when API key is configured" do
      let(:mock_search) { instance_double(GoogleSearch) }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("SERPAPI_KEY").and_return("test_api_key")
        allow(GoogleSearch).to receive(:new).and_return(mock_search)
      end

      context "when site is found in search results" do
        let(:mock_results) do
          {
            organic_results: [
              { link: "https://other-site.com/page", position: 1 },
              { link: "https://another-site.com/page", position: 2 },
              { link: "https://example.com/article", position: 3 }
            ]
          }
        end

        before do
          allow(mock_search).to receive(:get_hash).and_return(mock_results)
        end

        it "returns the correct rank position" do
          result = service.execute
          expect(result).to eq(3)
        end
      end

      context "when site is not found in results" do
        let(:mock_results) do
          {
            organic_results: [
              { link: "https://other-site.com/page", position: 1 },
              { link: "https://another-site.com/page", position: 2 }
            ]
          }
        end

        before do
          allow(mock_search).to receive(:get_hash).and_return(mock_results)
        end

        it "returns 101 (out of range)" do
          result = service.execute
          expect(result).to eq(101)
        end
      end

      context "when API returns an error" do
        before do
          allow(mock_search).to receive(:get_hash).and_raise(StandardError.new("API Error"))
        end

        it "logs the error and returns nil" do
          expect(Rails.logger).to receive(:error).with(/SerpApi Error: API Error/)
          result = service.execute
          expect(result).to be_nil
        end
      end
    end
  end

  describe "#check_rank" do
    context "when API key is not configured" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("SERPAPI_KEY").and_return(nil)
      end

      it "returns a mock result" do
        result = service.check_rank
        expect(result).to be_a(RankCheckerService::Result)
        expect(result.success?).to be true
        expect(result.rank).to be_between(1, 50)
      end
    end

    context "when API is configured" do
      let(:mock_search) { instance_double(GoogleSearch) }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("SERPAPI_KEY").and_return("test_api_key")
        allow(GoogleSearch).to receive(:new).and_return(mock_search)
        allow(service).to receive(:sleep) # Skip sleep in tests
      end

      context "when site is found in results" do
        let(:mock_results) do
          {
            organic_results: [
              { link: "https://other-site.com/page", position: 1 },
              { link: "https://example.com/page", position: 3 }
            ]
          }
        end

        before do
          allow(mock_search).to receive(:get_hash).and_return(mock_results)
        end

        it "returns the correct rank" do
          result = service.check_rank
          expect(result.success?).to be true
          expect(result.rank).to eq(3)
        end
      end

      context "when rate limited" do
        before do
          allow(mock_search).to receive(:get_hash).and_raise(RankCheckerService::RateLimitError.new("Rate limit"))
        end

        it "returns a rate_limited result after retries" do
          result = service.check_rank
          expect(result.rate_limited?).to be true
          expect(result.error_message).to include("rate limit")
        end
      end

      context "when API error occurs (403)" do
        before do
          allow(mock_search).to receive(:get_hash).and_raise(StandardError.new("403 Forbidden"))
        end

        it "returns an api_error result" do
          result = service.check_rank
          expect(result.failed?).to be true
          expect(result.status).to eq(:api_error)
          expect(result.error_message).to include("API access denied")
        end
      end

      context "when server error occurs" do
        before do
          allow(mock_search).to receive(:get_hash).and_raise(StandardError.new("500 Internal Server Error"))
        end

        it "returns an api_error result" do
          result = service.check_rank
          expect(result.failed?).to be true
          expect(result.status).to eq(:api_error)
          expect(result.error_message).to include("server error")
        end
      end

      context "when network error occurs" do
        before do
          allow(mock_search).to receive(:get_hash).and_raise(Faraday::ConnectionFailed.new("Connection refused"))
        end

        it "returns a network_error result after retries" do
          result = service.check_rank
          expect(result.failed?).to be true
          expect(result.status).to eq(:network_error)
          expect(result.error_message).to include("Network")
        end
      end
    end
  end

  describe "#exponential_backoff_delay" do
    it "increases delay exponentially" do
      delay1 = service.send(:exponential_backoff_delay, 1)
      delay2 = service.send(:exponential_backoff_delay, 2)
      delay3 = service.send(:exponential_backoff_delay, 3)

      # Base delay is 2 seconds, so:
      # retry 1: 2^1 * 2 = 4 seconds (plus jitter up to 1)
      # retry 2: 2^2 * 2 = 8 seconds (plus jitter up to 1)
      # retry 3: 2^3 * 2 = 16 seconds (plus jitter up to 1)
      expect(delay1).to be >= 4
      expect(delay1).to be < 5
      expect(delay2).to be >= 8
      expect(delay2).to be < 9
      expect(delay3).to be >= 16
      expect(delay3).to be < 17
    end
  end

  describe "#normalize_url (private)" do
    it "removes http:// prefix" do
      result = service.send(:normalize_url, "http://example.com")
      expect(result).to eq("example.com")
    end

    it "removes https:// prefix" do
      result = service.send(:normalize_url, "https://example.com")
      expect(result).to eq("example.com")
    end

    it "removes www. prefix" do
      result = service.send(:normalize_url, "https://www.example.com")
      expect(result).to eq("example.com")
    end

    it "removes trailing slash" do
      result = service.send(:normalize_url, "https://example.com/")
      expect(result).to eq("example.com")
    end

    it "converts to lowercase" do
      result = service.send(:normalize_url, "https://EXAMPLE.COM")
      expect(result).to eq("example.com")
    end

    it "handles nil gracefully" do
      result = service.send(:normalize_url, nil)
      expect(result).to eq("")
    end

    it "preserves path" do
      result = service.send(:normalize_url, "https://example.com/path/to/page")
      expect(result).to eq("example.com/path/to/page")
    end
  end

  describe "#find_rank_in_results (private)" do
    let(:organic_results) do
      [
        { link: "https://site1.com", position: 1 },
        { link: "https://site2.com", position: 2 },
        { link: "https://example.com/page", position: 3 }
      ]
    end

    it "finds the site in results and returns position" do
      result = service.send(:find_rank_in_results, organic_results)
      expect(result).to eq(3)
    end

    it "returns 101 when site is not found" do
      results = [
        { link: "https://other1.com", position: 1 },
        { link: "https://other2.com", position: 2 }
      ]
      result = service.send(:find_rank_in_results, results)
      expect(result).to eq(101)
    end

    it "returns 101 for nil input" do
      result = service.send(:find_rank_in_results, nil)
      expect(result).to eq(101)
    end

    it "returns 101 for empty array" do
      result = service.send(:find_rank_in_results, [])
      expect(result).to eq(101)
    end
  end

  describe "search parameters" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SERPAPI_KEY").and_return("test_api_key")
    end

    it "uses correct parameters for Japanese Google search" do
      expect(GoogleSearch).to receive(:new).with(
        hash_including(
          engine: "google",
          q: keyword_word,
          gl: "jp",
          hl: "ja",
          num: 100,
          api_key: "test_api_key"
        )
      ).and_return(double(get_hash: { organic_results: [] }))

      service.execute
    end
  end
end
