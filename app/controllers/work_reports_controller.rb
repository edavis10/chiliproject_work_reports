class WorkReportsController < ApplicationController
  unloadable
  before_filter :authorize_global

  def index
    @projects = get_projects_based_on_roll_up
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
