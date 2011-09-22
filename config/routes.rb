ActionController::Routing::Routes.draw do |map|
  map.resources :work_reports, :only => [:index]
  map.cumulative_flow_graph 'projects/:project_id/cumulative_flow.svg', :controller => 'project_cumulative_flow_graphs', :action => 'show'

end
