require "spec_helper"

describe Form do
  it_behaves_like "has a uuid"

  let(:mission) { create(:mission) }

  context "API User" do
    before do
      @api_user = FactoryGirl.create(:user)
      @mission = FactoryGirl.create(:mission, name: "test mission")
      @form = FactoryGirl.create(:form, mission: @mission, name: "something", access_level: 'protected')
      @form.whitelistings.create(user_id: @api_user.id)
    end

    it "should return true for user in whitelist" do
      expect(@form.api_user_id_can_see?(@api_user.id)).to be_truthy
    end

    it "should return false for user not in whitelist" do
      other_user = FactoryGirl.create(:user)
      expect(@form.api_user_id_can_see?(other_user.id)).to be_falsey
    end
  end

  describe "pub_changed_at" do
    before do
      @form = create(:form)
    end

    it "should be nil on create" do
      expect(@form.pub_changed_at).to be_nil
    end

    it "should be updated when form published" do
      @form.publish!
      expect(@form.pub_changed_at).to be_within(0.1).of(Time.zone.now)
    end

    it "should be updated when form unpublished" do
      publish_and_reset_pub_changed_at(save: true)
      @form.unpublish!
      expect(@form.pub_changed_at).to be_within(0.1).of(Time.zone.now)
    end

    it "should not be updated when form saved otherwise" do
      publish_and_reset_pub_changed_at
      @form.name = "Something else"
      @form.save!
      expect(@form.pub_changed_at).not_to be_within(5.minutes).of(Time.zone.now)
    end
  end

  describe "needs_odk_manifest?" do
    context "for form with single level option sets only" do
      before { @form = create(:form, question_types: %w(select_one)) }
      it "should return false" do
        expect(@form.needs_odk_manifest?).to be false
      end
    end
    context "for form with multi level option set" do
      before { @form = create(:form, question_types: %w(select_one multilevel_select_one)) }
      it "should return true" do
        expect(@form.needs_odk_manifest?).to be true
      end
    end
  end

  describe "odk_download_cache_key" do
    before do
      @form = create(:form)
      publish_and_reset_pub_changed_at
    end

    it "should be correct" do
      expect(@form.odk_download_cache_key).to eq "odk-form/#{@form.id}-#{@form.pub_changed_at}"
    end
  end

  describe "odk_index_cache_key" do
    before do
      @form = create(:form)
      @form2 = create(:form)
      publish_and_reset_pub_changed_at(save: true)
      publish_and_reset_pub_changed_at(form: @form2, diff: 30.minutes, save: true)
    end

    context "for mission with forms" do
      it "should be correct" do
        expect(Form.odk_index_cache_key(mission: get_mission)).to eq "odk-form-list/mission-#{get_mission.id}/#{@form2.pub_changed_at.utc.to_s(:cache_datetime)}"
      end
    end

    context "for mission with no forms" do
      before do
        @mission2 = create(:mission)
        create(:form, mission: @mission2) # Unpublished
      end
      it "should be correct" do
        expect(Form.odk_index_cache_key(mission: @mission2)).to eq "odk-form-list/mission-#{@mission2.id}/no-pubd-forms"
      end
    end
  end

  describe "root_group" do
    before do
      @mission = create(:mission)
    end

    it "has a root group when created from factory" do
      form = create(:form, mission: @mission, question_types: ["integer", ["text", "text"], "text"])
      expect(form.root_group).to_not be_nil
    end
  end

  describe "ancestry" do
    before do
      @mission = create(:mission)
      @form = create(:form, mission: @mission, question_types: ["integer", ["text", "text"], "text"])
    end

    it "has 3 children" do
      expect(@form.root_group.sorted_children.count).to eq 3
    end

    it "has one subgroup with two children" do
      expect(@form.root_group.sorted_children[1].sorted_children.count).to eq 2
    end
  end

  describe "destroy" do
    before do
      @form = create(:form, mission: mission, question_types: ["integer", ["text", "text"], "text"])
    end

    it "should work" do
      @form.destroy
      expect([Form.count, FormItem.count]).to eq [0,0]
    end

    it "should work with an smsable form" do
      @form.update_attributes(smsable: true)
      @form.destroy
      expect([Form.count, FormItem.count]).to eq [0,0]
    end
  end

  describe "destroy_questionings" do
    it "should work" do
      f = create(:form, question_types: %w(integer decimal decimal integer))
      f.destroy_questionings(f.root_questionings[1..2])
      f.reload

      # make sure they're gone and ranks are ok
      expect(f.root_questionings.count).to eq(2)
      expect(f.root_questionings.map(&:rank)).to eq([1,2])
    end
  end

  describe "all_required" do
    it "should work" do
      f = create(:form, question_types: %w(integer integer))
      expect(f.all_required?).to be false
      f.root_questionings.each{|q| q.required = true; q.save}
      expect(f.all_required?).to be true
    end
  end

  def publish_and_reset_pub_changed_at(options = {})
    f = options[:form] || @form
    f.publish!
    f.pub_changed_at -= (options[:diff] || 1.hour)
    f.save! if options[:save]
  end
end
