# frozen_string_literal: true

require "rails_helper"

RSpec.describe RankCheckerService do
  let(:keyword_word) { "test keyword" }
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

  describe "#check_rank" do
    context "when API key is not configured" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("GOOGLE_API_KEY").and_return(nil)
        allow(ENV).to receive(:fetch).and_call_original
      end

      it "returns a mock result" do
        result = service.check_rank
        expect(result).to be_a(RankCheckerService::Result)
        expect(result.success?).to be true
        expect(result.rank).to be_between(1, 50)
      end
    end

    context "when API is configured" do
      let(:mock_client) { instance_double(Google::Apis::CustomsearchV1::CustomSearchAPIService) }
      let(:mock_response) { double("SearchResponse", items: mock_items) }
      let(:mock_items) { [] }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("GOOGLE_API_KEY").and_return("test_api_key")
        allow(ENV).to receive(:[]).with("GOOGLE_SEARCH_ENGINE_ID").and_return("test_cx")
        allow(Google::Apis::CustomsearchV1::CustomSearchAPIService).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:key=)
        allow(mock_client).to receive(:key).and_return("test_api_key")
        allow(service).to receive(:sleep) # Skip sleep in tests
      end

      context "when site is found in results" do
        let(:mock_items) do
          [
            double("Item", link: "https://other-site.com/page"),
            double("Item", link: "https://other-site2.com/page"),
            double("Item", link: "https://example.com/page")
          ]
        end

        before do
          allow(mock_client).to receive(:list_cses).and_return(mock_response)
        end

        it "returns the correct rank" do
          result = service.check_rank
          expect(result.success?).to be true
          expect(result.rank).to eq(3)
        end
      end

      context "when rate limited" do
        before do
          rate_limit_error = Google::Apis::RateLimitError.new("Rate Limit Exceeded")
          allow(mock_client).to receive(:list_cses).and_raise(rate_limit_error)
        end

        it "returns a rate_limited result after retries" do
          result = service.check_rank
          expect(result.rate_limited?).to be true
          expect(result.error_message).to include("rate limit")
        end
      end

      context "when client error occurs (403)" do
        before do
          client_error = Google::Apis::ClientError.new("Forbidden", status_code: 403)
          allow(mock_client).to receive(:list_cses).and_raise(client_error)
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
          server_error = Google::Apis::ServerError.new("Internal Server Error")
          allow(mock_client).to receive(:list_cses).and_raise(server_error)
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
          allow(mock_client).to receive(:list_cses).and_raise(Faraday::ConnectionFailed.new("Connection refused"))
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
      # retry 1: 2^1 * 2 = 4 seconds (plus jitter)
      # retry 2: 2^2 * 2 = 8 seconds (plus jitter)
      # retry 3: 2^3 * 2 = 16 seconds (plus jitter)
      expect(delay1).to be >= 4
      expect(delay2).to be >= 8
      expect(delay3).to be >= 16
      expect(delay2).to be > delay1
      expect(delay3).to be > delay2
    end
  end
end
