class Rougemine::EnumerationsController < ApplicationController
  unloadable

  unless Gem::Version.new(Rails.version) < Gem::Version.new("3")
    accept_api_auth :index
  end

  def index
    respond_to do |format|
      format.api {
        Rails.logger.debug klasses
        @klass = klasses[params[:type].to_sym]
        if @klass
          @enumerations = @klass.shared.all(:order => 'position')
        else
          render_404
        end
      }
    end
  end

private

  def klasses
    {
      :time_entry_activities => TimeEntryActivity,
      :issue_priorities      => IssuePriority,
    }
  end

end
