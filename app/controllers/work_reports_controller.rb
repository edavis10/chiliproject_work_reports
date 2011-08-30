class WorkReportsController < ApplicationController
  unloadable
  before_filter :authorize_global

  def index
    render :text => 'Hello'
  end
end
