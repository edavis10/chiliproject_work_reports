require 'SVG/Graph/TimeSeries'

class WorkReportsController < ApplicationController
  unloadable
  rescue_from ::ChiliprojectWorkReports::KanbanNotConfiguredError, :with => :kanban_not_configured

  before_filter :authorize_global
  before_filter :check_kanban_configuration

  def index
    @projects = get_projects_based_on_roll_up
  end

  def graph
    @project = Project.find(params[:project_id])

    fields = []
    12.times {|m| fields << month_name(((Date.today.month - 1 - m) % 12) + 1)}

    graph = SVG::Graph::TimeSeries.new({
                                         :height => 300,
                                         :width => 400,
                                         :area_fill => true,
                                         :min_y_value => 0,
                                         :stagger_x_labels => true,
                                         :x_label_format => "%Y-%m-%d"
                                       })

    # Stack by adding previous data items

    data1 = {
      "2011-01-01" => 100,
      "2011-02-01" => 120,
      "2011-03-01" => 130,
      "2011-04-01" => 140
    }
    

    graphing_data1 = data1.inject([]) do |acc, data_item|
      acc << data_item.first # date
      acc << data_item.second # value
      acc
    end

    data2 = data1.dup

    # Some raw data
    {
      "2011-01-01" => 100,
      "2011-02-01" => 120,
      "2011-03-01" => 150,
      "2011-04-01" => 160
    }.each do |key, value|
      data2[key] ||= 0
      data2[key] += value
    end

    graphing_data2 = data2.inject([]) do |acc, data_item|
      acc << data_item.first # date
      acc << data_item.second # value
      acc
    end

    graph.add_data({
                     :data => graphing_data1,
                     :title => 'issues'
                   })
    
    graph.add_data({
                     :data => graphing_data2,
                     :title => 'issues2'
                   })
    
    
    headers["Content-Type"] = "image/svg+xml"
    send_data(graph.burn, :type => "image/svg+xml", :disposition => "inline")
  end

  protected
  # Check that the Kanban is configured and raise an exception if not
  def check_kanban_configuration
    unless ChiliprojectWorkReports::Configuration.kanban_configured? && 
        ChiliprojectWorkReports::Configuration.kanban_finished_configured? && 
        ChiliprojectWorkReports::Configuration.kanban_backlog_configured? && 
        ChiliprojectWorkReports::Configuration.kanban_incoming_configured?
      raise ChiliprojectWorkReports::KanbanNotConfiguredError
    end
  end
  
  def kanban_not_configured
    render :template => 'work_reports/kanban_not_configured', :status => 500
  end

  private

  def get_projects_based_on_roll_up
    projects = Project.visible.all(:order => 'lft asc')
    if ChiliprojectWorkReports::Configuration.kanban_roll_up_projects? &&
        ChiliprojectWorkReports::Configuration.kanban_roll_up_project_level > 0
      # Filter in Ruby, Project#level is a method not a field
      projects.reject! {|project| project.level >= ChiliprojectWorkReports::Configuration.kanban_roll_up_project_level }
    end
    projects
  end
end
