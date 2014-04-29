require "spec_helper"

describe "answers" do
  
  context "when getting all answers for one" do

    before do
      api_user = FactoryGirl.create(:user)
      form_user = FactoryGirl.create(:user)
      mission = FactoryGirl.create(:mission, name: "mission1") 
      form = FactoryGirl.create(:form, mission: mission, name: "something")
      q1 = FactoryGirl.create(:question, mission: mission)

      form.questions << [q1, q2]
      response_obj = FactoryGirl.create(:response, form: form, mission: mission, user: form_user)
      @a1 = FactoryGirl.create(:answer, response: response_obj, questioning_id: q1.id, value: 10)

      response_obj = FactoryGirl.create(:response, form: form, mission: mission, user: form_user)
      @a2 = FactoryGirl.create(:answer, response: response_obj, questioning_id: q1.id, value: 20)

      params = {form_id: form.id, question_id: q1.id}

      get api_v1_one_answer_path, params, {'HTTP_AUTHORIZATION' => "Token token=#{api_user.api_key}"}
      @answers = parse_json(response.body)
    end

    it "should return array of size 2" do
      expect(@answers.size).to eq 2
    end

    it "should contain answer 1 and 2" do
      expect(@answers.first.has_value?(@a1.value)).to be_true
      expect(@answers.last.has_value?(@a2.value)).to be_true
    end

  end

end