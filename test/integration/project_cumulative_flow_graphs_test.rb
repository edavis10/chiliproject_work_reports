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
      
      create_issue_with_backdated_history_at(10.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => issue_status_for_testing)
      create_issue_with_backdated_history_at(8.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => issue_status_for_testing)
      create_issue_with_backdated_history_at(4.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => issue_status_for_testing)

      create_issue_with_backdated_history_at(10.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => active_issue_status)
      create_issue_with_backdated_history_at(4.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => active_issue_status)
      create_issue_with_backdated_history_at(4.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => active_issue_status)

      create_issue_with_backdated_history_at(10.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => selected_issue_status)
      create_issue_with_backdated_history_at(8.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => selected_issue_status)
      create_issue_with_backdated_history_at(8.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => selected_issue_status)

      create_issue_with_backdated_history_at(12.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => backlog_issue_status)
      create_issue_with_backdated_history_at(8.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => backlog_issue_status)
      create_issue_with_backdated_history_at(6.months.ago, :project => @project_one, :subject => 'Issue1 on Project1', :status => backlog_issue_status)
    end

    should "see a SVG graph" do
      get_graph(@project_one)
      assert_content_type "image/svg+xml"
    end
    
    # Stacked from bottom
    should "see data points for tasks over the past 12 months on 5 separate lines" do
      get_graph(@project_one)
      svg = Nokogiri::XML(page.source)

      # Lines are ordered in reverse: 5 is the base, 4 stacks on top, etc
      assert_equal 1, svg.css('svg path.line5').length, "Should only have one Finished line"
      assert_equal 12, svg.css('svg circle.dataPoint5').length, "Should only have 12 data points for Finished"
      assert_equal 1, svg.css('svg path.line4').length, "Should only have one Testing line"
      assert_equal 12, svg.css('svg circle.dataPoint4').length, "Should only have 12 data points for Testing"
      assert_equal 1, svg.css('svg path.line3').length, "Should only have one Active line"
      assert_equal 12, svg.css('svg circle.dataPoint3').length, "Should only have 12 data points for Active"
      assert_equal 1, svg.css('svg path.line2').length, "Should only have one Selected line"
      assert_equal 12, svg.css('svg circle.dataPoint2').length, "Should only have 12 data points for Selected"
      assert_equal 1, svg.css('svg path.line1').length, "Should only have one Backlog line"
      assert_equal 12, svg.css('svg circle.dataPoint1').length, "Should only have 12 data points for Backlog"

      # Finished
      assert_svg_has_data_point_on_line(svg, :line_number => '5', :series => 0, :value => 1) # 12.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '5', :series => 1, :value => 1) # 11.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '5', :series => 2, :value => 2) # 10.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '5', :series => 3, :value => 2) # 9.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '5', :series => 4, :value => 3) # 8.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '5', :series => 5, :value => 3) # 7.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '5', :series => 6, :value => 4) # 6.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '5', :series => 7, :value => 4) # 5.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '5', :series => 8, :value => 5) # 4.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '5', :series => 9, :value => 5) # 3.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '5', :series => 10, :value => 6) # 2.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '5', :series => 11, :value => 6) # 1.months.ago

      # Testing - stacking starts
      assert_svg_has_data_point_on_line(svg, :line_number => '4', :series => 0, :value => 1 + 0) # 12.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '4', :series => 1, :value => 1 + 0) # 11.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '4', :series => 2, :value => 2 + 1) # 10.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '4', :series => 3, :value => 2 + 1) # 9.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '4', :series => 4, :value => 3 + 2) # 8.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '4', :series => 5, :value => 3 + 2) # 7.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '4', :series => 6, :value => 4 + 2) # 6.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '4', :series => 7, :value => 4 + 2) # 5.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '4', :series => 8, :value => 5 + 3) # 4.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '4', :series => 9, :value => 5 + 3) # 3.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '4', :series => 10, :value => 6 + 3) # 2.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '4', :series => 11, :value => 6 + 3) # 1.months.ago
      
      # Active
      assert_svg_has_data_point_on_line(svg, :line_number => '3', :series => 0, :value => 1 + 0 + 0) # 12.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '3', :series => 1, :value => 1 + 0 + 0) # 11.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '3', :series => 2, :value => 2 + 1 + 1) # 10.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '3', :series => 3, :value => 2 + 1 + 1) # 9.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '3', :series => 4, :value => 3 + 2 + 1) # 8.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '3', :series => 5, :value => 3 + 2 + 1) # 7.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '3', :series => 6, :value => 4 + 2 + 1) # 6.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '3', :series => 7, :value => 4 + 2 + 1) # 5.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '3', :series => 8, :value => 5 + 3 + 3) # 4.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '3', :series => 9, :value => 5 + 3 + 3) # 3.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '3', :series => 10, :value => 6 + 3 + 3) # 2.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '3', :series => 11, :value => 6 + 3 + 3) # 1.months.ago

      # Selected
      assert_svg_has_data_point_on_line(svg, :line_number => '2', :series => 0, :value => 1 + 0 + 0 + 0) # 12.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '2', :series => 1, :value => 1 + 0 + 0 + 0) # 11.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '2', :series => 2, :value => 2 + 1 + 1 + 1) # 10.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '2', :series => 3, :value => 2 + 1 + 1 + 1) # 9.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '2', :series => 4, :value => 3 + 2 + 1 + 3) # 8.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '2', :series => 5, :value => 3 + 2 + 1 + 3) # 7.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '2', :series => 6, :value => 4 + 2 + 1 + 3) # 6.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '2', :series => 7, :value => 4 + 2 + 1 + 3) # 5.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '2', :series => 8, :value => 5 + 3 + 3 + 3) # 4.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '2', :series => 9, :value => 5 + 3 + 3 + 3) # 3.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '2', :series => 10, :value => 6 + 3 + 3 + 3) # 2.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '2', :series => 11, :value => 6 + 3 + 3 + 3) # 1.months.ago

      # Backlog
      assert_svg_has_data_point_on_line(svg, :line_number => '1', :series => 0, :value => 1 + 0 + 0 + 0 + 1) # 12.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '1', :series => 1, :value => 1 + 0 + 0 + 0 + 1) # 11.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '1', :series => 2, :value => 2 + 1 + 1 + 1 + 1) # 10.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '1', :series => 3, :value => 2 + 1 + 1 + 1 + 1) # 9.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '1', :series => 4, :value => 3 + 2 + 1 + 3 + 2) # 8.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '1', :series => 5, :value => 3 + 2 + 1 + 3 + 2) # 7.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '1', :series => 6, :value => 4 + 2 + 1 + 3 + 3) # 6.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '1', :series => 7, :value => 4 + 2 + 1 + 3 + 3) # 5.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '1', :series => 8, :value => 5 + 3 + 3 + 3 + 3) # 4.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '1', :series => 9, :value => 5 + 3 + 3 + 3 + 3) # 3.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '1', :series => 10, :value => 6 + 3 + 3 + 3 + 3) # 2.months.ago
      assert_svg_has_data_point_on_line(svg, :line_number => '1', :series => 11, :value => 6 + 3 + 3 + 3 + 3) # 1.months.ago
    end

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
