require 'SVG/Graph/TimeSeries'

class ProjectCumulativeFlowGraphsController < ApplicationController
  unloadable
  before_filter :find_project_by_project_id
  before_filter :authorize

  def show
    finished_count = count_of_issues_in_status_by_month(ChiliprojectWorkReports::Configuration.kanban_finished_issue_status)

    graph = SVG::Graph::TimeSeries.new({
                                         :height => 300,
                                         :width => 400,
                                         :area_fill => true,
                                         :min_y_value => 0,
                                         :stagger_x_labels => true,
                                         :x_label_format => "%Y-%m"
                                       })

    # Sort hash data to a format for SVG: [first_date, first_date_value, second_date, second_date_value..]
    finished_issues_for_svg = finished_count.sort_by {|k,v| k }.inject([]) do |acc, data_item|
                       acc << data_item.first.strftime("%Y-%m-%d") # date
                       acc << data_item.second # value
                       acc
    end

    graph.add_data({
                     :title => 'finished issues',
                     :data => finished_issues_for_svg
                   })

    headers["Content-Type"] = "image/svg+xml"
    send_data(graph.burn, :type => "image/svg+xml", :disposition => "inline")
  end

  private

  def count_of_issues_in_status_by_month(status)
    months.inject({}) do |counter, date|
      start_date = date.beginning_of_month.to_datetime
      end_date = start_date + 1.month - 1.second

      # Map of issue_ids and if they changed from or to a status.
      issue_map = {}
      # Order by creation date so changes later in the month override previous ones
      IssueJournal.all(:conditions => ["journaled_id IN (:issue_ids) AND created_at > :start_date AND created_at < :end_date AND changes LIKE (:status)",
                                       {
                                         :issue_ids => @project.issues.collect(&:id),
                                         :start_date => start_date,
                                         :end_date => end_date,
                                         :status => '%status%'
                                       }],
                       :order => "created_at asc").each do |journal|
        next unless journal.changes["status_id"].present?

        # Change to incoming
        if journal.changes["status_id"].last == status.id
          issue_map[journal.journaled_id] = :to
        end
        # Change from incoming
        if journal.changes["status_id"].first == status.id
          issue_map[journal.journaled_id] = :from
        end
      end

      counter[date] = starting_count_for_month(date, counter)
      issue_map.each do |issue_id, change|
        case change
        when :from
          counter[date] -= 1
        when :to
          counter[date] += 1
        end
        
      end
      counter
    end
  end

  def starting_count_for_month(date, month_counter)
    # Fetch previous month's value to build on
    current_position = months.index(date)
    if current_position
      previous_position = current_position - 1
      previous_position_date = months[previous_position]
      # Copy previous month's value over
      if previous_position_date && month_counter[previous_position_date].present?
        return month_counter[previous_position_date]
      end
    end
      
    return 0
  end

  def months
    months = []
    12.times do |increment|
      months << (1.year.ago.beginning_of_month + increment.months).to_date
    end
    months
  end
end
