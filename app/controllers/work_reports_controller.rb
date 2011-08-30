class WorkReportsController < ApplicationController
  unloadable
  before_filter :authorize_global

  def index
    @projects = Project.visible.all(:order => 'lft asc')
  end
end
