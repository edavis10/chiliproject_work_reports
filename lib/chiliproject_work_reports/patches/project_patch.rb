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
        # Calculate the average number of days issues have spent in the Backlog status
        #
        # (Backlog status is provided from the Kanban configuration)
        #
        # @param [Hash] options the options to use when calculating
        # @option options [bool] :include_subprojects Include issues on subprojects?
        def backlog_time(options={})
          return 0 if issues.count == 0
          raise ChiliprojectWorkReports::KanbanNotConfiguredError unless kanban_backlog_configured?

          issues_to_check = if options.delete(:include_subprojects)
                              project_ids = self_and_descendants.collect(&:id)
                              Issue.all(:conditions => ["#{Issue.table_name}.project_id IN (?)", project_ids])
                            else
                              issues
                            end

          backlog_durations = issues_to_check.inject([]) do |time_spans, issue|
            time_spans << issue.days_in_backlog unless issue.days_in_backlog.nil?
            time_spans
          end

          total_time = backlog_durations.sum
          number_of_issues = backlog_durations.length
          return 0 if number_of_issues == 0
          return (total_time / number_of_issues)
        end

        def backlog_issue_status
          @backlog_issue_status ||= IssueStatus.find(Setting.plugin_redmine_kanban["panes"]["backlog"]["status"])
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
