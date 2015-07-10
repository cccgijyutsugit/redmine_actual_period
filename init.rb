require 'redmine'
require 'issue_patch'
require 'issue_query_patch'
require 'time_entry_patch'
require_dependency "view_hooks"

Redmine::Plugin.register :redmine_actual_period do
  name 'Redmine Actual Period plugin'
  author 'MIYAWAKI Anna (CCC)'
  description 'This plugin enables you to view actual working period (which automatically calculated on time-entry records).'
  version '0.1.0'
  url 'https://github.com/cccgijyutsugit/redmine_actual_period'
  author_url 'https://github.com/cccgijyutsugit'
end
