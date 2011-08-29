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
        def backlog_time
          return 0 if issues.count == 0
          raise ChiliprojectWorkReports::KanbanNotConfiguredError unless kanban_backlog_configured?

          backlog_durations = issues.inject([]) do |time_spans, issue|
            journals_in_reverse = issue.journals.all(:order => 'version DESC',
                                                     :conditions => ["#{Journal.table_name}.created_at > ?", 30.days.ago])

            last_time_changed_to_backlog = issue.last_time_changed_to_backlog(journals_in_reverse)

            unless issue.currently_in_backlog?
              last_time_changed_from_backlog = issue.last_time_changed_from_backlog(journals_in_reverse)
            end

            time_spans << case
                          when issue.currently_in_backlog? && last_time_changed_to_backlog.present?
                            Date.today - last_time_changed_to_backlog.created_at.to_date
                          when last_time_changed_to_backlog.present? && last_time_changed_from_backlog.present?
                            last_time_changed_from_backlog.created_at.to_date - last_time_changed_to_backlog.created_at.to_date
                          else
                            # Never entered backlog
                            nil
                          end
            time_spans
          end

          # Toss issues that never entered backlog
          backlog_durations.compact!
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
