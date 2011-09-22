module ChiliprojectWorkReports
  class Configuration

    def self.settings
      Setting.plugin_chiliproject_work_reports || {}
    end

    def self.kanban_settings
      if kanban_configured?
        Setting.plugin_redmine_kanban
      else
        {}
      end
    end
    
    def self.kanban_configured?
      Setting.respond_to?(:plugin_redmine_kanban) &&
        Setting.plugin_redmine_kanban.present?
    end

    def self.kanban_finished_configured?
      begin
        kanban_configured? &&
          Setting.plugin_redmine_kanban.fetch("panes").fetch("finished").fetch("status").present?
      rescue IndexError
        false
      end
    end

    def self.kanban_incoming_configured?
      begin
        kanban_configured? &&
          Setting.plugin_redmine_kanban.fetch("panes").fetch("incoming").fetch("status").present?
      rescue IndexError
        false
      end
    end

    def self.kanban_backlog_configured?
      begin
        kanban_configured? &&
          Setting.plugin_redmine_kanban.fetch("panes").fetch("backlog").fetch("status").present?
      rescue IndexError
        false
      end
    end

    def self.kanban_testing_configured?
      begin
        kanban_configured? &&
          Setting.plugin_redmine_kanban.fetch("panes").fetch("testing").fetch("status").present?
      rescue IndexError
        false
      end
    end

    def self.kanban_active_configured?
      begin
        kanban_configured? &&
          Setting.plugin_redmine_kanban.fetch("panes").fetch("active").fetch("status").present?
      rescue IndexError
        false
      end
    end

    def self.kanban_selected_configured?
      begin
        kanban_configured? &&
          Setting.plugin_redmine_kanban.fetch("panes").fetch("selected").fetch("status").present?
      rescue IndexError
        false
      end
    end

    def self.kanban_roll_up_projects?
      kanban_configured? && Setting.plugin_redmine_kanban["rollup"].to_i == 1
    end

    def self.kanban_roll_up_project_level
      kanban_configured? && kanban_roll_up_projects? && Setting.plugin_redmine_kanban["project_level"].to_i
    end

    def self.kanban_backlog_issue_status
      if kanban_backlog_configured?
        IssueStatus.find(Setting.plugin_redmine_kanban["panes"]["backlog"]["status"])
      end
    end

    def self.kanban_testing_issue_status
      if kanban_testing_configured?
        IssueStatus.find(Setting.plugin_redmine_kanban["panes"]["testing"]["status"])
      end
    end

    def self.kanban_active_issue_status
      if kanban_testing_configured?
        IssueStatus.find(Setting.plugin_redmine_kanban["panes"]["active"]["status"])
      end
    end

    def self.kanban_selected_issue_status
      if kanban_testing_configured?
        IssueStatus.find(Setting.plugin_redmine_kanban["panes"]["selected"]["status"])
      end
    end

    def self.kanban_finished_issue_status
      if kanban_finished_configured?
        IssueStatus.find(Setting.plugin_redmine_kanban["panes"]["finished"]["status"])
      end
    end
    
    def self.kanban_incoming_issue_status
      if kanban_incoming_configured?
        IssueStatus.find(Setting.plugin_redmine_kanban["panes"]["incoming"]["status"])
      end
    end
    
  end
end
