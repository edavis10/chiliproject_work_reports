module ChiliprojectWorkReports
  module Patches
    module ProjectPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          extend ActiveSupport::Memoizable
          # TODO: memoizes the options param too
          memoize :backlog_time
          memoize :completion_time
          memoize :incoming_issue_rate
          memoize :finished_issue_rate

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

          issues_to_check = if options[:include_subprojects]
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

        def finished_issue_status
          @finished_issue_status ||= IssueStatus.find(Setting.plugin_redmine_kanban["panes"]["finished"]["status"])
        end

        def incoming_issue_status
          @incoming_issue_status ||= IssueStatus.find(Setting.plugin_redmine_kanban["panes"]["incoming"]["status"])
        end

        # Calculate the average number of days issues have spent from Backlog to Finished
        #
        # (Backlog and Finished status are provided from the Kanban configuration)
        def completion_time(options={})
          return 0 if issues.count == 0
          raise ChiliprojectWorkReports::KanbanNotConfiguredError unless kanban_backlog_configured?
          raise ChiliprojectWorkReports::KanbanNotConfiguredError unless kanban_finished_configured?

          issues_to_check = if options[:include_subprojects]
                              project_ids = self_and_descendants.collect(&:id)
                              Issue.all(:conditions => ["#{Issue.table_name}.project_id IN (?)", project_ids])
                            else
                              issues
                            end

          completion_durations = issues_to_check.inject([]) do |time_spans, issue|
            time_span = issue.days_from_statuses(backlog_issue_status, finished_issue_status)
            time_spans << time_span unless time_span.nil?
            time_spans
          end

          total_time = completion_durations.sum
          number_of_issues = completion_durations.length
          return 0 if number_of_issues == 0
          return (total_time / number_of_issues)
        end

        # Calculate the change in issues for the incoming status. Returned as the change:
        #
        # Example:
        # - 2 added issues
        # - 3 removed issues
        # - would return -1 (+2-3)
        # @param [Hash] options the options to use when calculating
        # @option options [bool] :include_subprojects Include issues on subprojects?
        def incoming_issue_rate(options={})
          raise ChiliprojectWorkReports::KanbanNotConfiguredError unless kanban_incoming_configured?

          issues_to_check = if options[:include_subprojects]
                              project_ids = self_and_descendants.collect(&:id)
                              Issue.all(:conditions => ["#{Issue.table_name}.project_id IN (?)", project_ids])
                            else
                              issues
                            end

          count_of_changes = issues_to_check.inject(0) do |counter, issue|
            # Was changed to incoming, including new issues
            counter += 1 if issue.last_time_status_changed_to(incoming_issue_status)
            # Was changed from incoming, lowers the count.
            counter -= 1 if issue.last_time_status_changed_from(incoming_issue_status)
            counter
          end
        end
        
        # Calculate the change in issues for the finished status. Returned as the change:
        #
        # Example:
        # - 2 added issues
        # - 3 removed issues
        # - would return -1 (+2-3)
        # @param [Hash] options the options to use when calculating
        # @option options [bool] :include_subprojects Include issues on subprojects?
        def finished_issue_rate(options={})
          raise ChiliprojectWorkReports::KanbanNotConfiguredError unless kanban_finished_configured?

          issues_to_check = if options[:include_subprojects]
                              project_ids = self_and_descendants.collect(&:id)
                              Issue.all(:conditions => ["#{Issue.table_name}.project_id IN (?)", project_ids])
                            else
                              issues
                            end

          count_of_changes = issues_to_check.inject(0) do |counter, issue|
            # Was changed to incoming, including new issues
            counter += 1 if issue.last_time_status_changed_to(finished_issue_status)
            # Was changed from incoming, lowers the count.
            counter -= 1 if issue.last_time_status_changed_from(finished_issue_status)
            counter
          end
        end

        # Calculate the issue growth rate for the past 30 days based on the incoming
        # and finished statuses.
        #
        # Example:
        # - 2 issues added to incoming
        # - 3 issues removed from incoming
        # - 1 issue added to finished
        # - 2 issues removed from finished
        # - would return 0 = ((2-3) - (1-2))
        # @param [Hash] options the options to use when calculating
        # @option options [bool] :include_subprojects Include issues on subprojects?
        def issue_growth_rate(options={})
          incoming_issue_rate(options) - finished_issue_rate(options)
        end
        
        private

        def kanban_configured?
          ChiliprojectWorkReports::Configuration.kanban_configured?
        end
        
        def kanban_finished_configured?
          ChiliprojectWorkReports::Configuration.kanban_finished_configured?
        end

        def kanban_backlog_configured?
          ChiliprojectWorkReports::Configuration.kanban_backlog_configured?
        end

        def kanban_incoming_configured?
          ChiliprojectWorkReports::Configuration.kanban_incoming_configured?
        end
      end
    end
  end
end
