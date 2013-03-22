require 'redmine'

require_dependency 'rougemine/hooks'

# Get the latest version of the plugin for prevent an upgrade

Redmine::Plugin.register :rougemine do
  name 'Rougemine plugin'
  author 'Opsone'
  description 'This is a plugin for Rougemine mobile application'
  version '1.0.2'
  url 'http://rougemine.opsone.net'
  author_url 'http://www.opsone.net'
  requires_redmine :version_or_higher => '1.1.0'
end
