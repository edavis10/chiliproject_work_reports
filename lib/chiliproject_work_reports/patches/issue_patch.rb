module ChiliprojectWorkReports
  module Patches
    module IssuePatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          extend ActiveSupport::Memoizable
          memoize :last_30_days_of_journals_in_reverse

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
          last_time_status_changed_to(backlog_issue_status)
        end

        def last_time_changed_from_backlog
          if currently_in_backlog?
            Time.now
          else
            last_time_status_changed_from(backlog_issue_status)
          end
        end

        def last_time_status_changed_from(status)
          # Looking for From status to other: "status_id" => [status, other]
          last_time_changed = last_30_days_of_journals_in_reverse.detect {|journal|
            journal.changes["status_id"].present? &&
            journal.changes["status_id"].first == status.id
          }

          if last_time_changed.present?
            last_time_changed.created_at
          end
        end

        def last_time_status_changed_to(status)
          # Looking for From other to status: "status_id" => [other, status]
          last_time_changed = last_30_days_of_journals_in_reverse.detect {|journal|
            journal.changes["status_id"].present? &&
            journal.changes["status_id"].last == status.id
          }

          if last_time_changed.present?
            last_time_changed.created_at
          end
        end

        def days_in_backlog
          if last_time_changed_to_backlog.present? && last_time_changed_from_backlog.present?
            return last_time_changed_from_backlog.to_date - last_time_changed_to_backlog.to_date
          else
            nil
          end
        end

        # Calculates the number of days it took for an issue to change
        # from one status to another.
        #
        # Not required to be linear:
        #  A => B => C
        #  days_from_statuses(A, C) would count B's time
        def days_from_statuses(from_status, to_status)
          start_day = last_time_status_changed_to(from_status)
          end_day = last_time_status_changed_to(to_status)
          if start_day.present? && end_day.present?
            return end_day.to_date - start_day.to_date
          else
            nil
          end
        end
      end
    end
  end
end
