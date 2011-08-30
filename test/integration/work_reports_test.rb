require 'test_helper'

class WorkReportsTest < ActionController::IntegrationTest
  def setup
    @allowed_user = User.generate!(:password => 'test', :password_confirmation => 'test').reload
    @denied_user = User.generate!(:password => 'test', :password_confirmation => 'test').reload
    @project_one = Project.generate!.reload
    @project_two = Project.generate!.reload
    @role = Role.generate!(:permissions => [:view_work_reports])
    User.add_to_project(@allowed_user, @project_one, @role)
    User.add_to_project(@allowed_user, @project_two, @role)
  end

  context "when logged in as a user without permission to 'view work reports'" do
    setup do
      login_as(@denied_user.login, 'test')
      visit_home
    end

    should "not be able to access Word Reports" do
      page.driver.get "/work_reports" # Direct url access
      assert_response :forbidden
    end
  end

end
