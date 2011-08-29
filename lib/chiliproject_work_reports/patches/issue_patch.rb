module ChiliprojectWorkReports
  module Patches
    module IssuePatch
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
        def backlog_issue_status
          project.backlog_issue_status
        end
        
        # When was this issue last changed into the backlog status?
        def last_time_changed_to_backlog(journals)
          # Looking for From other to backlog: "status_id" => [other, backlog]
          last_time_changed_to_backlog = journals.detect {|journal|
            journal.changes["status_id"].present? &&
            journal.changes["status_id"].last == backlog_issue_status.id
          }

        end
      end
    end
  end
end
