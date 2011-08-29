require 'redmine'
require 'chiliproject_work_reports'

Redmine::Plugin.register :chiliproject_work_reports do
  name 'Chiliproject Work Reports plugin'
  author 'Author name'
  description 'This is a plugin for ChiliProject'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end
require 'dispatcher'
Dispatcher.to_prepare :chiliproject_work_reports do

  require_dependency 'project'
  Project.send(:include, ChiliprojectWorkReports::Patches::ProjectPatch)
end
