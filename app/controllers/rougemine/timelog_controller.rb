class Rougemine::TimelogController < ApplicationController
  unloadable

  unless Gem::Version.new(Rails.version) < Gem::Version.new("3")
    accept_api_auth :index
  end

  helper :sort
  include SortHelper
  helper :issues
  include TimelogHelper
  helper :custom_fields
  include CustomFieldsHelper

  def index
    sort_init 'spent_on', 'desc'
    sort_update 'spent_on' => ['spent_on', "#{TimeEntry.table_name}.created_on"],
                'user' => 'user_id',
                'activity' => 'activity_id',
                'project' => "#{Project.table_name}.name",
                'issue' => 'issue_id',
                'hours' => 'hours'

    if Gem::Version.new(Redmine::VERSION.to_s) < Gem::Version.new("2")
      index_redmine11
    else
      index_redmine22
    end
  end

private

  def index_redmine11
    cond = ARCondition.new

    if !params[:assigned_to_id].blank?
      cond << ['user_id = ?', params[:assigned_to_id]]
    end

    if @project.nil?
      cond << Project.allowed_to_condition(User.current, :view_time_entries)
    elsif @issue.nil?
      cond << @project.project_condition(Setting.display_subprojects_issues?)
    else
      cond << "#{Issue.table_name}.root_id = #{@issue.root_id} AND #{Issue.table_name}.lft >= #{@issue.lft} AND #{Issue.table_name}.rgt <= #{@issue.rgt}"
    end

    retrieve_date_range
    cond << ['spent_on BETWEEN ? AND ?', @from, @to]

    TimeEntry.visible_by(User.current) do
      respond_to do |format|
        format.api  {
          @entry_count = TimeEntry.count(:include => [:project, :issue], :conditions => cond.conditions)
          @entry_pages = Paginator.new self, @entry_count, per_page_option, params['page']
          @entries = TimeEntry.find(:all, 
                                    :include => [:project, :activity, :user, {:issue => :tracker}],
                                    :conditions => cond.conditions,
                                    :order => sort_clause,
                                    :limit  =>  @entry_pages.items_per_page,
                                    :offset =>  @entry_pages.current.offset)
        }
      end
    end
  end

  def index_redmine22
    scope = TimeEntry.visible.spent_between(@from, @to)

    if !params[:assigned_to_id].blank?
      scope = scope.where('user_id = ?', params[:assigned_to_id])
    end

    if @issue
      scope = scope.on_issue(@issue)
    elsif @project
      scope = scope.on_project(@project, Setting.display_subprojects_issues?)
    end

    respond_to do |format|
      format.api  {
        @entry_count = scope.count
        @offset, @limit = api_offset_and_limit
        @entries = scope.all(
          :include => [:project, :activity, :user, {:issue => :tracker}],
          :order => sort_clause,
          :limit  => @limit,
          :offset => @offset
        )
      }
    end
  end

end
