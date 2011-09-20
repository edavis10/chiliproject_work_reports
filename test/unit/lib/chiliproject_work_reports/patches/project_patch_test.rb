require File.dirname(__FILE__) + '/../../../../test_helper'

class ChiliprojectWorkReports::Patches::ProjectTest < ActionController::TestCase
  context "Project" do
    setup do
      configure_kanban_plugin
      @project = Project.generate!
      @child_project = Project.generate!
      @child_project.set_parent!(@project)
      @child_child_project = Project.generate!
      @child_child_project.set_parent!(@child_project)
      @project.reload
      @other_status = IssueStatus.generate!

      @issue1 = create_issue_with_backdated_history(60, :project => @project, :subject => 'Over 40')
      @issue2 = create_issue_with_backdated_history(60, :project => @project, :subject => 'Changed')
      @issue3 = create_issue_with_backdated_history(60, :project => @project, :subject => 'Still backlog')
      @child_issue = create_issue_with_backdated_history(60, :project => @child_project, :subject => 'Child')
      @child_child_issue = create_issue_with_backdated_history(60, :project => @child_child_project, :subject => 'Child child')
      
      # 40 days ago #1 was set to backlog
      update_issue_status_with_backdated_history(@issue1, 40, backlog_issue_status)
      # 20 days ago #2, #3, #child, and #child_child were set to backlog
      update_issue_status_with_backdated_history(@issue2, 20, backlog_issue_status)
      update_issue_status_with_backdated_history(@issue3, 20, backlog_issue_status)
      update_issue_status_with_backdated_history(@child_issue, 20, backlog_issue_status)
      update_issue_status_with_backdated_history(@child_child_issue, 20, backlog_issue_status)
      # 10 days ago #1 was set to finished
      update_issue_status_with_backdated_history(@issue1, 10, @finished_issue_status)
      # 5 days ago #child were set to other status
      update_issue_status_with_backdated_history(@child_issue, 5, @other_status)
      # 5 days ago #2 and #child_child were set to finished
      update_issue_status_with_backdated_history(@issue2, 5, @finished_issue_status)
      update_issue_status_with_backdated_history(@child_child_issue, 5, @finished_issue_status)
      # 2 days ago #child were set to finished
      update_issue_status_with_backdated_history(@child_issue, 2, @finished_issue_status)
      Timecop.return
      # Backlog duration:
      #  #1 => 40-10 = 30 days, started backlog 40 days ago
      #  #2 => 20-5 = 15 days, started backlog 20 days ago
      #  #3 => 20-0 = 20 days (still set), started backlog 20 days ago
      #  #child => 20-5 = 15 days, started backlog 20 days ago
      #  #child_child => 20-5 = 15 days, started backlog 20 days ago
      # Backlog => Finished:
      #  #1 => 40-10 = 30 day completion
      #  #2 => 20-5 = 15 day completion
      #  #3 => 20-nil = never completed
      #  #child => 20-2 = 18 day completion
      #  #child_child => 20-5 = 15 day completion
    end

    context "#backlog_time" do      
      should "return 0 if there are no issues" do
        @project.issues.destroy_all
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
      
      should "return the average number of days an issue has been in the backlog for the past 30 days" do
        # Skips #1 (started backlog out of date range)
        # (#2 = 15, #3 = 20) / 2 = 17.5
        assert_equal 17.5, @project.backlog_time
      end

      should "allow including issues on subprojects in the calcuation" do
        # Skips #1 (started backlog out of date range)
        # (#2 = 15, #3 = 20, #child = 15, #child_child = 15) / 4 = 16.25
        assert_equal 16.25, @project.backlog_time(:include_subprojects => true)
      end
      
    end

    context "#completion_time" do
      should "return 0 if there are no issues" do
        @project.issues.destroy_all
        assert @project.issues.empty?
        assert_equal 0, @project.completion_time
      end
      
      should "raise an error if the Kanban plugin is not configured" do
        Setting['plugin_redmine_kanban'] = {}
        assert_raises ChiliprojectWorkReports::KanbanNotConfiguredError do
          @project.completion_time
        end
      end
      
      should "raise an error if the Kanban backlog status is not configured" do
        Setting['plugin_redmine_kanban'] = {"panes" => {"backlog" => {}}}
        assert_raises ChiliprojectWorkReports::KanbanNotConfiguredError do
          @project.completion_time
        end
      end

      should "raise an error if the Kanban finished status is not configured" do
        Setting['plugin_redmine_kanban'] = {"panes" => {"finished" => {}}}
        assert_raises ChiliprojectWorkReports::KanbanNotConfiguredError do
          @project.completion_time
        end
      end

      should "return the average number of days for an issue to go from backlog to finished for the past 30 days" do
        # Skips #1, over 30 days
        # (#2 = 15) / 1 = 15
        assert_equal 15, @project.completion_time
      end

      should "allow including issues on subprojects in the calcuation" do
        # Skips #1, over 30 days
        # (#2 = 15, #child = 18, #child_child = 15) / 3 = 16
        assert_equal 16, @project.completion_time(:include_subprojects => true)
      end
      
    end
    
  end
end
