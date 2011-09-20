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

    def self.kanban_backlog_configured?
      begin
        kanban_configured? &&
          Setting.plugin_redmine_kanban.fetch("panes").fetch("backlog").fetch("status").present?
      rescue IndexError
        false
      end
    end


  end
end
