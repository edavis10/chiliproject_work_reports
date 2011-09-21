class WorkReportsController < ApplicationController
  unloadable
  rescue_from ::ChiliprojectWorkReports::KanbanNotConfiguredError, :with => :kanban_not_configured

  before_filter :authorize_global
  before_filter :check_kanban_configuration

  def index
    @projects = get_projects_based_on_roll_up
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
