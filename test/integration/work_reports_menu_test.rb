require 'test_helper'

class WorkReportsMenuTest < ActionController::IntegrationTest
  def setup
    configure_kanban_plugin
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
      visit_home
    end
    
    should "see a top menu item for Work Reports" do
      assert find("#top-menu li a", :text => "Work Reports")
    end
    
    context "when clicking the Work Reports" do
      should "show the Work Report page" do
        click_link "Work Reports"

        assert_response :success
        assert_equal "/work_reports", current_path
      end
    end
    
  end

  context "when logged in as a user without permission to 'view work reports'" do
    setup do
      login_as(@denied_user.login, 'test')
      visit_home
    end

    should "not see a top menu item for Work Reports" do
      assert has_no_content?("Work Reports")
    end
  end

end
