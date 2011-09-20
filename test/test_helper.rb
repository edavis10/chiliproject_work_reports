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
    # Creation
    issue = nil
    Timecop.freeze(created_days_ago.days.ago) do
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
