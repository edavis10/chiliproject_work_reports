require File.dirname(__FILE__) + '/../../../../test_helper'

class ChiliprojectWorkReports::Patches::ProjectTest < ActionController::TestCase
  context "Project" do
    context "#backlog_time" do
      setup do
        configure_kanban_plugin
        @project = Project.generate!
        @issue1 = Issue.generate_for_project!(@project)
      end
      
      should "return 0 if there are no issues" do
        @issue1.destroy
        assert @project.issues.empty?
        assert_equal 0, @project.backlog_time
      end
      
      should "raise an error if the Kanban plugin is not configured" do
        Setting['plugin_redmine_kanban'] = {}
        assert_raises ChiliprojectWorkReports::KanbanNotConfiguredError do
          @project.backlog_time
        end
      end
      
      should "raise an error if the Kanban backlog status is not configured" do
        Setting['plugin_redmine_kanban'] = {"panes" => {}}
        assert_raises ChiliprojectWorkReports::KanbanNotConfiguredError do
          @project.backlog_time
        end
      end
      
      should "return the average number of days an issue has been in the backlog for the past 30 days"
    end
  end
end
