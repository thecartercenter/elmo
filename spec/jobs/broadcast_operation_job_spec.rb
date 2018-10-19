# frozen_string_literal: true

require "rails_helper"

describe BroadcastOperationJob do
  let(:operation) { create(:operation, mission: create(:mission)) }
  let(:broadcast) { create(:broadcast, medium: "sms", recipient_users: [create(:user)]) }

  describe "#perform" do
    it "calls broadcast#deliver" do
      expect(broadcast).to receive(:deliver)
      described_class.perform_now(operation, broadcast)
    end

    it "saves sent_at time" do
      described_class.perform_now(operation, broadcast)
      expect(broadcast.reload.sent_at).not_to be_nil
    end

    context "when PartialError is raised" do
      before do
        allow(Sms::Broadcaster).to receive(:deliver).and_raise(Sms::Adapters::PartialSendError)
      end

      it "marks operation as completed" do
        described_class.perform_now(operation, broadcast)
        expect(operation.reload.completed?).to eq(true)
      end

      it "saves job error report" do
        described_class.perform_now(operation, broadcast)
        expect(operation.reload.job_error_report).to match(/errors delivering some messages/)
      end
    end

    context "when FatalError is raised" do
      before do
        allow(Sms::Broadcaster).to receive(:deliver).and_raise(Sms::Adapters::FatalSendError)
      end

      it "marks operation as failed" do
        described_class.perform_now(operation, broadcast)
        expect(operation.reload.failed?).to eq(true)
      end

      it "saves job error report" do
        described_class.perform_now(operation, broadcast)
        expect(operation.reload.job_error_report).to match(/for more information/)
      end
    end
  end
end
