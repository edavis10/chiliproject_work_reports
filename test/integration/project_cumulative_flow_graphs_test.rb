require 'test_helper'
require 'nokogiri'

class ProjectCumulativeFlowGraphsTest < ActionController::IntegrationTest
  def setup
    configure_kanban_plugin
    @allowed_user = User.generate!(:password => 'test', :password_confirmation => 'test').reload
    @denied_user = User.generate!(:password => 'test', :password_confirmation => 'test').reload
    @project_one = Project.generate!.reload
    @role = Role.generate!(:permissions => [:view_cumulative_flow_graph])
    User.add_to_project(@allowed_user, @project_one, @role)
  end

  def get_graph(project)
    page.driver.get "/projects/#{project.id}/cumulative_flow.svg" # Direct url access
  end

  context "when logged in as a user with permission to 'view cumulative flow graph'" do
    setup do
      login_as(@allowed_user.login, 'test')

      create_issue_with_backdated_history_at(12.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => finished_issue_status)
      create_issue_with_backdated_history_at(10.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => finished_issue_status)
      create_issue_with_backdated_history_at(8.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => finished_issue_status)
      create_issue_with_backdated_history_at(6.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => finished_issue_status)
      create_issue_with_backdated_history_at(4.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => finished_issue_status)
      create_issue_with_backdated_history_at(2.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => finished_issue_status)
      
    end

    should "see a SVG graph" do
      get_graph(@project_one)
      assert_content_type "image/svg+xml"
    end
    
    # Stacked from bottom
    should "see dataPointLabels for finished tasks for 12 months"
    should "see dataPointLabels for testing tasks for 12 months"
    should "see dataPointLabels for active tasks for 12 months"
    should "see dataPointLabels for selected tasks for 12 months"
    should "see dataPointLabels for backlog tasks for 12 months"

  end

  context "when logged in as a user without permission to 'view cumulative flow graph'" do
    setup do
      login_as(@denied_user.login, 'test')
      visit_home
    end

    should "not be able to access" do
      get_graph(@project_one)
      assert_response :forbidden
    end
  end

end
