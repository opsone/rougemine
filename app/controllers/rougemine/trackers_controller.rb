class Rougemine::TrackersController < ApplicationController
  unloadable

  unless Gem::Version.new(Rails.version) < Gem::Version.new("3")
    before_filter :require_admin_or_api_request, :only => :index
    accept_api_auth :index
  end

  def index
    respond_to do |format|
      format.api {
        @trackers = Tracker.find(:all, :order => 'position')
      }
    end
  end
end