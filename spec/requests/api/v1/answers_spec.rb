require "spec_helper"
require "support/shared_context"

describe "answers" do
  
  context "when getting for one question" do
    
    include_context "mission_form_and_two_responses_answered"

    before do
      get api_v1_answers_path, @params, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
      @answers_array = parse_json(response.body)
    end

    it "should return array of size 2" do
      expect(@answers_array.size).to eq 2
    end

    it "should contain an answer from each response" do
      expect(@answers_array.first.has_value?(@a1.value)).to be_true
      expect(@answers_array.last.has_value?(@a2.value)).to be_true
    end

  end

  context "when getting for one public form with 1 private questions" do
    
    include_context "mission_form_one_private_question"

    before do
      @form.update_attribute(:access_level, AccessLevel::PUBLIC)
      get api_v1_answers_path, @params, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
      @answers_array = parse_json(response.body)
    end

    it "should return array of size 0" do
      expect(@answers_array.size).to eq 0
    end

  end

  context "when getting for one private form with 1 private questions" do
    
    include_context "mission_form_one_private_question"

    before do
      @form.update_attribute(:access_level, AccessLevel::PRIVATE)
      get api_v1_answers_path, @params, {'HTTP_AUTHORIZATION' => "Token token=#{@api_user.api_key}"}
      @answers_array = parse_json(response.body)
    end

    it "should return array of size 0" do
      expect(@answers_array.size).to eq 0 
    end

  end

end
