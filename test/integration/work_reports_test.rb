require 'test_helper'

class WorkReportsTest < ActionController::IntegrationTest
  def setup
    configure_kanban_plugin
    @allowed_user = User.generate!(:password => 'test', :password_confirmation => 'test').reload
    @denied_user = User.generate!(:password => 'test', :password_confirmation => 'test').reload
    @project_one = Project.generate!.reload
    @project_two = Project.generate!.reload
    @child_project = Project.generate!
    @child_project.set_parent!(@project_one)
    @child_child_project = Project.generate!
    @child_child_project.set_parent!(@child_project)
    @project_one.reload
    @role = Role.generate!(:permissions => [:view_work_reports])
    User.add_to_project(@allowed_user, @project_one, @role)
    User.add_to_project(@allowed_user, @project_two, @role)
    User.add_to_project(@allowed_user, @child_project, @role)
    User.add_to_project(@allowed_user, @child_child_project, @role)
  end

  context "when logged in as a user with permission to 'view work reports'" do
    setup do
      login_as(@allowed_user.login, 'test')
    end
    
    should "see a list of projects with no rollup" do
      visit_work_reports

      assert find(".projects #project_#{@project_one.id}")
      assert find(".projects #project_#{@project_two.id}")
      assert find(".projects #project_#{@child_project.id}")
      assert find(".projects #project_#{@child_child_project.id}")
    end
    
    should "roll up projects based on the Kanban rollup configuration" do
      kanban_enable_rollup_to_level(1)
      assert_equal 1, ChiliprojectWorkReports::Configuration.kanban_roll_up_project_level
      visit_work_reports

      assert find(".projects #project_#{@project_one.id}")
      assert find(".projects #project_#{@project_two.id}")
      assert has_no_css?(".projects #project_#{@child_project.id}")
      assert has_no_css?(".projects #project_#{@child_child_project.id}")

    end

    context "project stats" do
      setup do
        @other_status = IssueStatus.generate!

        @issue1_project_1 = create_issue_with_backdated_history(60, :project => @project_one, :subject => 'Issue1 on Project1')
        @issue2_project_1 = create_issue_with_backdated_history(60, :project => @project_one, :subject => 'Issue2 on Project1')
        @issue1_project_child_child = create_issue_with_backdated_history(60, :project => @child_child_project, :subject => 'Issue1 on ProjectChildChild')
        # Into backlog 20 days ago, moved out 10 days ago, finished 5 days ago
        update_issue_status_with_backdated_history(@issue1_project_1, 20, backlog_issue_status)
        update_issue_status_with_backdated_history(@issue1_project_1, 10, @other_status)
        update_issue_status_with_backdated_history(@issue1_project_1, 5, @finished_issue_status)
        # Into backlog 10 days ago, finished 5 days ago
        update_issue_status_with_backdated_history(@issue2_project_1, 10, backlog_issue_status)
        update_issue_status_with_backdated_history(@issue2_project_1, 5, @finished_issue_status)
        # Into backlog 10 days ago, finished 5 days ago
        update_issue_status_with_backdated_history(@issue1_project_child_child, 10, backlog_issue_status)
        update_issue_status_with_backdated_history(@issue1_project_child_child, 5, @finished_issue_status)

        Timecop.return
        assert !ChiliprojectWorkReports::Configuration.kanban_roll_up_projects?
      end

      should "show the Backlog Time, in days" do
        visit_work_reports

        assert find("#project_#{@project_one.id}")
        within("#project_#{@project_one.id}") do
          # AVG((20-10), (10-5))
          assert find(".backlog-time", :text => /7.5/)
        end
      end
      
      should "show the Average Completion time, in days" do
        visit_work_reports

        assert find("#project_#{@project_one.id}")
        within("#project_#{@project_one.id}") do
          # AVG((20-5), (10-5))
          assert find(".completion-time", :text => /10/)
        end

      end
      
      should "show the Incoming Rate, in issue count"
      should "show the Completion Rate, in issue count"
      should "show the Growth Rate, in issue count"

      should "roll up subproject stats" do
        kanban_enable_rollup_to_level(1)
        assert_equal 1, ChiliprojectWorkReports::Configuration.kanban_roll_up_project_level
        visit_work_reports

        assert find("#project_#{@project_one.id}")
        within("#project_#{@project_one.id}") do
          # AVG((20-10), (10-5), (10-5))
          assert find(".backlog-time", :text => /6.7/)
          # AVG((20-5), (10-5), (10-5))
          assert find(".completion-time", :text => /8.3/)
        end

      end
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
