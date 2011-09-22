# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path


require 'capybara/rails'


def User.add_to_project(user, project, role)
  Member.generate!(:principal => user, :project => project, :roles => [role])
end

module ChiliProjectIntegrationTestHelper
  def login_as(user="existing", password="existing")
    visit "/logout" # Make sure the session is cleared

    visit "/login"
    fill_in 'Login', :with => user
    fill_in 'Password', :with => password
    click_button 'Login'
    assert_response :success
    assert User.current.logged?
  end

  def visit_home
    visit '/'
    assert_response :success
  end

  def visit_project(project)
    visit_home
    assert_response :success

    click_link 'Projects'
    assert_response :success

    click_link project.name
    assert_response :success
  end

  def visit_issue_page(issue)
    visit '/issues/' + issue.id.to_s
  end

  def visit_issue_bulk_edit_page(issues)
    visit url_for(:controller => 'issues', :action => 'bulk_edit', :ids => issues.collect(&:id))
  end

  def visit_work_reports
    visit_home
    click_link "Work Reports"

    assert_response :success
    assert_equal "/work_reports", current_path
  end
  
  # Capybara doesn't set the response object so we need to glue this to
  # it's own object but without @response
  def assert_response(code)
    # Rewrite human status codes to numeric
    converted_code = case code
                     when :success
                       200
                     when :forbidden
                       403
                     when :missing
                       404
                     when :redirect
                       302
                     when :error
                       500
                     when code.is_a?(Symbol)
                       ActionController::StatusCodes::SYMBOL_TO_STATUS_CODE[code]
                     else
                       code
                     end

    assert_equal converted_code, page.status_code
  end

  def assert_content_type(expected)
    assert_equal expected, page.response_headers['Content-Type']
  end

end

class ActionController::IntegrationTest
  include ChiliProjectIntegrationTestHelper
  
  include Capybara
  
end

class ActiveSupport::TestCase
  begin
    require 'ruby_gc_test_patch'
    include RubyGcTestPatch
  rescue LoadError
  end
  
  def assert_forbidden
    assert_response :forbidden
    assert_template 'common/403'
  end

  def assert_svg_has_data_point(nokogiri_doc, text, options={})
    count = options[:count] || 1

    matching_elements = nokogiri_doc.css('svg text.dataPointLabel').select {|element|
      element.content.strip == text.to_s
    }

    # SVG is creating two text elements per data point
    assert_equal count * 2, matching_elements.length
  end

  def assert_svg_has_data_point_on_line(nokogiri_doc, options={})
    line_number = options[:line_number]
    series = options[:series]
    value = options[:value]

    data_point = nokogiri_doc.css("svg circle.dataPoint#{line_number}")[series]
    assert data_point, "Data point circle not found"
    y = data_point["cy"]
    x = data_point["cx"]
    y = y.to_f - 6 # labels are offset a bit above data point
    data_point_label = nokogiri_doc.css("svg text.dataPointLabel[x='#{x}'][y='#{y}']").try(:first)
    assert data_point_label, "Data point label not found"
    assert_equal value.to_s, data_point_label.content.strip, "Data point content not matching"
  end
  
  def configure_plugin(configuration_change={})
    Setting.plugin_TODO = {
      
    }.merge(configuration_change)
  end

  def reconfigure_plugin(configuration_change)
    Setting['plugin_chiliproject_work_reports'] = Setting['plugin_chiliproject_work_reports'].merge(configuration_change)
  end

  def incoming_issue_status
    @incoming_issue_status ||= IssueStatus.generate!(:name => 'Incoming')
  end

  def backlog_issue_status
    @backlog_issue_status ||= IssueStatus.generate!(:name => 'Backlog')
  end
  
  def issue_status_for_testing # T::U name conflict as testing_issue_status
    @testing_issue_status ||= IssueStatus.generate!(:name => 'Testing')
  end

  def active_issue_status
    @active_issue_status ||= IssueStatus.generate!(:name => 'Active')
  end

  def selected_issue_status
    @selected_issue_status ||= IssueStatus.generate!(:name => 'Selected')
  end

  def finished_issue_status
    @finished_issue_status ||= IssueStatus.generate!(:name => 'Finished', :is_closed => true)
  end

  def kanban_enable_rollup_to_level(level)
    Setting['plugin_redmine_kanban'] =
      Setting['plugin_redmine_kanban'].merge({
                                               "rollup" => "1",
                                               "project_level" => level.to_s
                                             })
  end

  def configure_kanban_plugin
    Setting['plugin_redmine_kanban'] = {
      "rollup" => "0",
      "project_level" => "1",
      "panes" => {
        "incoming" => {
          "status" => incoming_issue_status.id.to_s
        },
        "backlog" => {
          "status" => backlog_issue_status.id.to_s
        },
        "selected" => {
          "status" => selected_issue_status.id.to_s
        },
        "active" => {
          "status" => active_issue_status.id.to_s
        },
        "testing" => {
          "status" => issue_status_for_testing.id.to_s
        },
        "finished" => {
          "status" => finished_issue_status.id.to_s
        }
      }
    }
  end

  # Create an issue with backdated historic data
  #
  # @param [Hash] attributes Attributes for the issue, :project is required
  def create_issue_with_backdated_history(created_days_ago, attributes)
    create_issue_with_backdated_history_at(created_days_ago.days.ago, attributes)
  end

  # Create an issue with backdated historic data at a specific date
  #
  # @param [Hash] attributes Attributes for the issue, :project is required
  def create_issue_with_backdated_history_at(creation_date, attributes)
    # Creation
    issue = nil
    Timecop.freeze(creation_date) do
      issue = Issue.generate_for_project!(attributes.delete(:project), attributes)
    end
    issue
  end

  # Update an issue's history
  def update_issue_status_with_backdated_history(issue, updated_days_ago, status)
    Timecop.freeze(updated_days_ago.days.ago) do
      issue.status = status
      assert issue.save
    end
    issue
  end
end
