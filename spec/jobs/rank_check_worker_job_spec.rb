# frozen_string_literal: true

require "rails_helper"

RSpec.describe RankCheckWorkerJob, type: :job do
  let(:user) { create(:user) }
  let(:site) { create(:site, user: user) }
  let(:keyword) { create(:keyword, site: site) }

  describe "#perform" do
    context "when rank check succeeds" do
      let(:success_result) { RankCheckerService::Result.new(rank: 10, status: :success) }

      before do
        allow_any_instance_of(RankCheckerService).to receive(:check_rank).and_return(success_result)
        allow(AlertGeneratorService).to receive(:generate_for_keyword)
      end

      it "creates a successful rank history record" do
        expect {
          described_class.perform_now(keyword.id)
        }.to change(RankHistory, :count).by(1)

        history = keyword.rank_histories.last
        expect(history.rank).to eq(10)
        expect(history.status).to eq("success")
        expect(history.error_message).to be_nil
      end

      it "calls AlertGeneratorService" do
        expect(AlertGeneratorService).to receive(:generate_for_keyword).with(keyword)
        described_class.perform_now(keyword.id)
      end
    end

    context "when rank check fails with api_error" do
      let(:error_result) do
        RankCheckerService::Result.new(
          status: :api_error,
          error_message: "API access denied"
        )
      end

      before do
        allow_any_instance_of(RankCheckerService).to receive(:check_rank).and_return(error_result)
      end

      it "creates a failed rank history record" do
        expect {
          described_class.perform_now(keyword.id)
        }.to change(RankHistory, :count).by(1)

        history = keyword.rank_histories.last
        expect(history.rank).to eq(0)
        expect(history.status).to eq("api_error")
        expect(history.error_message).to include("API access denied")
      end
    end

    context "when rank check fails with rate_limited" do
      let(:rate_limit_result) do
        RankCheckerService::Result.new(
          status: :rate_limited,
          error_message: "Rate limit exceeded"
        )
      end

      before do
        allow_any_instance_of(RankCheckerService).to receive(:check_rank).and_return(rate_limit_result)
      end

      it "raises an error to trigger retry" do
        expect {
          described_class.perform_now(keyword.id)
        }.to raise_error(RankCheckerService::RateLimitError)
      end

      it "does not leave a permanent failure record after retry" do
        # The job creates a record then deletes it before raising
        # So after the job completes (with error), there should be no record
        begin
          described_class.perform_now(keyword.id)
        rescue RankCheckerService::RateLimitError
          # Expected
        end

        expect(keyword.rank_histories.for_date(Date.current).count).to eq(0)
      end
    end

    context "when already checked today with success" do
      before do
        create(:rank_history, keyword: keyword, checked_at: Date.current, rank: 15)
      end

      it "skips the check" do
        expect_any_instance_of(RankCheckerService).not_to receive(:check_rank)
        described_class.perform_now(keyword.id)
      end

      it "does not create another record" do
        expect {
          described_class.perform_now(keyword.id)
        }.not_to change(RankHistory, :count)
      end
    end

    context "when already checked today with failure" do
      before do
        create(:rank_history, :failed, keyword: keyword, checked_at: Date.current)
      end

      it "skips the check (failure already recorded)" do
        expect_any_instance_of(RankCheckerService).not_to receive(:check_rank)
        described_class.perform_now(keyword.id)
      end
    end

    context "when keyword does not exist" do
      it "handles the missing record gracefully" do
        # With discard_on ActiveRecord::RecordNotFound, the job is discarded
        # This should not raise an error
        expect {
          described_class.perform_now(999999)
        }.not_to raise_error
      end
    end

    context "when unexpected error occurs" do
      before do
        allow_any_instance_of(RankCheckerService).to receive(:check_rank).and_raise(StandardError, "Unexpected")
      end

      it "records the failure and re-raises" do
        expect {
          described_class.perform_now(keyword.id)
        }.to raise_error(StandardError)

        history = keyword.rank_histories.last
        expect(history).to be_present
        expect(history.status).to eq("failed")
        expect(history.error_message).to include("Unexpected")
      end
    end
  end

  describe "job configuration" do
    it "uses the default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end
end
