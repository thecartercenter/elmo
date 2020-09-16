# frozen_string_literal: true

require "rails_helper"
require "json"

describe SentryJob do
  it "gets created automatically" do
    expect(Delayed::Job.count).to eq(0)
    Raven.capture_message("Test")
    expect(Delayed::Job.count).to eq(1)
  end
end
