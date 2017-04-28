require "spec_helper"

describe User do
  it_behaves_like "has a uuid"

  let(:mission) { get_mission }

  context "when user is created" do
    before do
      @user = create(:user)
    end

    it "should have an api_key generated" do
      expect(@user.api_key).to_not be_blank
    end

    it "should have an SMS auth code generated" do
      expect(@user.sms_auth_code).to_not be_blank
    end
  end

  describe "best_mission" do
    before do
      @user = build(:user)
    end

    context "with no last mission" do
      context "with no assignments" do
        before { allow(@user).to receive(:assignments).and_return([]) }
        specify { expect(@user.best_mission).to be_nil }
      end

      context "with assignments" do
        before do
          allow(@user).to receive(:assignments).and_return([
                           build(:assignment, user: @user, updated_at: 2.days.ago),
            @most_recent = build(:assignment, user: @user, updated_at: 1.hour.ago),
                           build(:assignment, user: @user, updated_at: 1.day.ago)
          ])
        end

        it "should return the mission from the most recently updated assignment" do
          expect(@user.best_mission).to eq @most_recent.mission
        end
      end
    end

    context "with last mission" do
      before do
        @last_mission = build(:mission)
        allow(@user).to receive(:last_mission).and_return(@last_mission)
      end

      context "and a more recent assignment to another mission" do
        before do
          allow(@user).to receive(:assignments).and_return([
            build(:assignment, user: @user, mission: @last_mission, updated_at: 2.days.ago),
            build(:assignment, user: @user, updated_at: 1.hour.ago)
          ])
        end

        specify { expect(@user.best_mission.name).to eq @last_mission.name }
      end

      context "but no longer assigned to last mission" do
        before { allow(@user).to receive(:assignments).and_return([]) }
        specify { expect(@user.best_mission).to be_nil }
      end
    end
  end

  describe "username validation" do
    it "should allow letters numbers and periods" do
      ["foobar", "foo.bar9", "1234", "..1_23"].each do |login|
        user = build(:user, login: login)
        expect(user).to be_valid
      end
    end

    it "should not allow invalid chars" do
      ["foo bar", "foo✓bar", "foébar", "foo'bar"].each do |login|
        user = build(:user, login: login)
        expect(user).not_to be_valid
        expect(user.errors[:login].join).to match /letters, numbers, periods/
      end
    end

    it "should trim spaces and convert to lowercase" do
      user = build(:user, login: "FOOBAR  \n ")
      expect(user).to be_valid
      expect(user.login).to eq "foobar"
    end
  end

  it "creating a user with minimal info should produce good defaults" do
    user = User.create!(name: "Alpha Tester", login: "alpha", reset_password_method: "print",
                        assignments: [Assignment.new(mission: mission, role: User::ROLES.first)])
    expect(user.pref_lang).to eq("en")
    expect(user.login).to eq("alpha")
  end

  it "phone numbers should be unique" do
    # create a user with two phone numbers
    first = create(:user, phone: "+19998887777", phone2: "+17776665537")

    assert_phone_uniqueness_error(build(:user, login: "foo", phone: "+19998887777"))
    assert_phone_uniqueness_error(build(:user, login: "foo", phone2: "+19998887777"))
    assert_phone_uniqueness_error(build(:user, login: "foo", phone: "+17776665537"))
    assert_phone_uniqueness_error(build(:user, login: "foo", phone2: "+17776665537"))

    # User with no phone.
    second = build(:user, login: "foo")
    expect(second).to be_valid

    # Try to edit this new user to conflicting phone number, should fail
    second.assign_attributes(phone: "+19998887777")
    assert_phone_uniqueness_error(second)

    # Create a user with different phone numbers and make sure no error
    third = build(:user, login: "bar", phone: "+19998887770", phone2: "+17776665530")
    expect(third).to be_valid
  end

  private
  def assert_phone_uniqueness_error(user)
    user.valid?
    expect(user.errors.full_messages.join).to match(/phone.+assigned/i)
  end
end
