module ChiliprojectWorkReports
  module Patches
    module ProjectPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def backlog_time
          return 0 if issues.count == 0
          raise ChiliprojectWorkReports::KanbanNotConfiguredError unless kanban_backlog_configured?
        end

        private

        def kanban_backlog_configured?
          begin
            Setting.respond_to?(:plugin_redmine_kanban) &&
              Setting.plugin_redmine_kanban.present? &&
              Setting.plugin_redmine_kanban.fetch("panes").fetch("backlog").fetch("status").present?
          rescue IndexError
            false
          end
        end
      end
    end
  end
end
