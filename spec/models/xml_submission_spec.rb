require 'spec_helper'

describe XMLSubmission do
  include ODKSubmissionSupport

  before do
    @form = create(:form, question_types: ['integer', ['integer', 'integer']])
    @form.publish!
    @response = create(:response, form: @form)
    @data = build_odk_submission(@form)
  end

  describe '.new' do
    it 'creates a submission and parses it to populate response' do
      submission = XMLSubmission.new(response: @response, data: @data)
      response = submission.response
      response.answers.each_with_index do |answer|
        expect(answer.group_number).to eq nil unless answer.from_group?
      end
      expect(response).to be_valid
    end
  end
end
