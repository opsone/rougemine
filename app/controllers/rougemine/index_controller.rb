class Rougemine::IndexController < ApplicationController
  unloadable

  unless Gem::Version.new(Rails.version) < Gem::Version.new("3")
    accept_api_auth :informations
  end

  def informations
    respond_to do |format|
      format.api {
        @infos = Redmine::Plugin.find(:rougemine)
      }
    end
  end
end
