# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

if Gem::Version.new(Rails.version) < Gem::Version.new("3")
  ActionController::Routing::Routes.draw do |map|

    map.with_options(:namespace => "rougemine") do |rougemine|
      rougemine.connect 'rougemine/projects/:project_id/wikis.:format', :controller => 'wiki', :action => 'index', :conditions => {:method => :get}

      rougemine.connect 'rougemine/infos.:format',              :controller => 'index',          :action => 'informations', :conditions => {:method => :get}
      rougemine.connect 'rougemine/informations.:format',       :controller => 'index',          :action => 'informations', :conditions => {:method => :get}
      rougemine.connect 'rougemine/enumerations/:type.:format', :controller => 'enumerations',   :action => 'index', :conditions => {:method => :get}
      rougemine.connect 'rougemine/issue_statuses.:format',     :controller => 'issue_statuses', :action => 'index', :conditions => {:method => :get}
      rougemine.connect 'rougemine/trackers.:format',           :controller => 'trackers',       :action => 'index', :conditions => {:method => :get}
      rougemine.connect 'rougemine/time_entries.:format',       :controller => 'timelog',        :action => 'index', :conditions => {:method => :get}
    end

  end
else
  RedmineApp::Application.routes.draw do

    scope "/rougemine", :module => "rougemine" do
      get 'projects/:project_id/wikis' => 'wiki#index'

      get 'infos'              => 'index#informations'
      get 'informations'       => 'index#informations'
      get 'enumerations/:type' => 'enumerations#index'
      get 'issue_statuses'     => 'issue_statuses#index'
      get 'trackers'           => 'trackers#index'
      get 'time_entries'       => 'timelog#index'
    end

  end
end