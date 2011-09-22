class ProjectCumulativeFlowGraphsController < ApplicationController
  unloadable
  before_filter :find_project_by_project_id
  before_filter :authorize

  def show
    headers["Content-Type"] = "image/svg+xml"
    send_data("hi", :type => "image/svg+xml", :disposition => "inline")
  end
end
