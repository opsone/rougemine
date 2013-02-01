class Rougemine::WikiController < ApplicationController
  unloadable

  unless Gem::Version.new(Rails.version) < Gem::Version.new("3")
    accept_api_auth :index
  end

  def index
    @project = Project.find(params[:project_id])
    render_404 unless @project.wiki

    respond_to do |format|
      format.api {
        @wikis = @project.wiki.pages.all(:order => 'title', :include => {:wiki => :project})
      }
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
