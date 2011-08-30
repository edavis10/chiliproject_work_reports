ActionController::Routing::Routes.draw do |map|
  map.resources :work_reports, :only => [:index]
end
