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

  context "when logged in as a user with permission to 'view work reports'" do
    setup do
      login_as(@allowed_user.login, 'test')
      visit_work_reports
    end
    
    should "see a list of projects" do
      assert find(".projects #project_#{@project_one.id}")
      assert find(".projects #project_#{@project_two.id}")
    end
    
    should "roll up projects based on the Kanban rollup configuration"

    context "project stats" do
      should "show the Average Completion time, in days"
      should "show the Incoming Rate, in issue count"
      should "show the Completion Rate, in issue count"
      should "show the Growth Rate, in issue count"
    end

    context "graphs" do
      should "show some graphs (TBD)"
    end
    
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
