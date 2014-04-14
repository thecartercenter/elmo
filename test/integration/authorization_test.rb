require 'test_helper'

class AuthorizationTest < ActionDispatch::IntegrationTest

  setup do
    @other_mission = FactoryGirl.create(:mission, :name => "Other")
  end

  test "guests can see login page" do
    assert_can_access(nil, login_path)
  end

  test "user can login and see welcome screen" do
    @user = FactoryGirl.create(:user)
    assert_can_access(@user, root_path)
  end

  test "anybody can logout" do
    @user = FactoryGirl.create(:user)
    # even guest can go to the logout page and get a sensible response (reduced confusion if back button used)
    assert_can_access(nil, logout_path, :redirected_to => logged_out_path)
    # logged in user can logout
    assert_can_access(@user, logout_path, :redirected_to => logged_out_path)
  end

  test "guest redirected to login page with message if unauthorized" do
    assert_can_access(nil, missions_path, :redirected_to => login_url)
    assert_select("div.alert-danger", /must login/)
  end

  test "user redirected to root if unauthorized" do
    @user = FactoryGirl.create(:user, :role_name => :observer, :admin => false)
    assert_cannot_access(@user, settings_path)
  end

  test "coordinator can only view forms for current mission" do
    @user = FactoryGirl.create(:user, :role_name => :coordinator)
    @form1 = FactoryGirl.create(:form)
    @form2 = FactoryGirl.create(:form, :mission_id => @other_mission.id)
    assert_can_access(@user, forms_path)
  end

  test "observer can update own name" do
    user = FactoryGirl.create(:user, :role_name => :observer, :name => 'foo')
    login(user)
    put(user_path(user), :user => {:name => 'bar'})
    assert_response(302) # redirected
    assert_equal('bar', user.reload.name)
  end

  test "observer cant update own role" do
    user = FactoryGirl.create(:user, :role_name => :observer)
    login(user)
    assignments_attributes = user.assignments.first.attributes.slice(*%w(id mission_id)).merge('role' => 'staffer')
    put(user_path(user), :user => {:assignments_attributes => [assignments_attributes]})
    assert_equal(true, assigns(:access_denied))
    assert_equal('observer', user.reload.assignments.first.role)
  end

  test "coordinator can update role of user in same mission" do
    coord = FactoryGirl.create(:user, :role_name => :coordinator)
    obs = FactoryGirl.create(:user, :role_name => :observer)
    login(coord)
    assignments_attributes = obs.assignments.first.attributes.slice(*%w(id mission_id)).merge('role' => 'staffer')
    put(user_path(obs), :user => {:assignments_attributes => [assignments_attributes]})
    assert_nil(assigns(:access_denied))
    assert_equal('staffer', obs.reload.assignments.first.role)
  end

  test "admin with no assignments should not lose current mission on login" do
    admin = FactoryGirl.create(:user, :admin => true)
    admin.assignments.destroy_all
    admin.change_mission!(get_mission)
    login(admin)
    assert_equal(get_mission, admin.current_mission)
  end

  test "admin with no assignments should and no current mission should stay with no current mission" do
    admin = FactoryGirl.create(:user, :admin => true)
    admin.assignments.destroy_all
    login(admin)
    assert_nil(admin.current_mission)
  end

  private
    # logs in a user and attempts to load the given path
    # errors if the response is not 200
    def assert_can_access(user, path, options = {})
      login(user) if user

      get(path)

      if options[:redirected_to]
        # check to make sure we were redirected properly
        assert_redirected_to(options[:redirected_to])
        # follow the redirect and look for a message
        follow_redirect!
      end

      assert_response(options[:expected_response] || :success)
    end

    def assert_cannot_access(user, path, options = {})
      login(user) if user
      get(path)
      assert_redirected_to(root_url)
      assert_match(flash[:error], /not authorized/)
    end
end