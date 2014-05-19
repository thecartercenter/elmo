require 'spec_helper'

describe API::V1::FormsController do

  context "when user has access" do
    before do
      @api_user = FactoryGirl.create(:user)
      controller.should_receive(:authenticate_token).and_return(@api_user)
    end

    context "views a mission and all forms" do
      before do
        @mission = FactoryGirl.create(:mission, name: "mission1")
        @form1 = @mission.forms.create(name: "test1")
        @form2 = @mission.forms.create(name: "test2")
        @protected_forms = Form.create(name: "protected", access_level: AccessLevel::PROTECTED)
        controller.stub(:protected_forms).and_return([@protected_forms])
      end

      it "should return status of 200" do
        get :index, {format: :json, mission_name: "mission1" }
        expect(response.status).to eq 200
      end

      it "should return json" do
        get :index, {format: :json, mission_name: "mission1" }
        expect(response.content_type).to eq Mime::JSON
      end
    end

    context "views meta data on a particular form" do
      before do
        @mission = FactoryGirl.create(:mission, name: "mission1")
        @form = @mission.forms.create(name: "test1" )
      end

      it "should find a form" do
        get :show, id: @form.id
        expect(response.status).to eq 200
      end

      it "should return json" do
        get :show, {format: :json, id: @form.id }
        expect(response.content_type).to eq Mime::JSON
      end       
    end
  end


  context "when user does not have access" do
    before do
      controller.should_receive(:authenticate_token).and_return(false)
    end

    it "should return 401" do
      get :index, {format: :json, mission_name: "this_will_fail"}  
      expect(response.status).to eq 401
    end
  end

end