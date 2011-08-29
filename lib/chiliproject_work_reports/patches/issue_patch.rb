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

        def currently_in_backlog?
          status == backlog_issue_status
        end

        def last_30_days_of_journals_in_reverse
          journals.all(:order => 'version DESC',
                       :conditions => ["#{Journal.table_name}.created_at > ?", 30.days.ago])
        end
        
        # When was this issue last changed into the backlog status?
        def last_time_changed_to_backlog
          # Looking for From other to backlog: "status_id" => [other, backlog]
          last_time_changed_to_backlog = last_30_days_of_journals_in_reverse.detect {|journal|
            journal.changes["status_id"].present? &&
            journal.changes["status_id"].last == backlog_issue_status.id
          }

          if last_time_changed_to_backlog.present?
            last_time_changed_to_backlog.created_at
          end
        end

        def last_time_changed_from_backlog
          if currently_in_backlog?
            Time.now
          else
            # Looking for From backlog to other: "status_id" => [backlog, other]
            last_time_changed_from_backlog = last_30_days_of_journals_in_reverse.detect {|journal|
              journal.changes["status_id"].present? &&
              journal.changes["status_id"].first == backlog_issue_status.id
            }

            if last_time_changed_from_backlog.present?
              last_time_changed_from_backlog.created_at
            end
          end
        end
      end
    end
  end
end
