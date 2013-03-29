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

    if Gem::Version.new(Redmine::VERSION.to_s) < Gem::Version.new("1.4")
      index_redmine11
    elsif Gem::Version.new(Redmine::VERSION.to_s) < Gem::Version.new("2")
      index_redmine14
    else
      index_redmine22
    end
  end

private

  def index_redmine11
    cond = ::ARCondition.new

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

    retrieve_date_range_11
    cond << ['spent_on BETWEEN ? AND ?', @from, @to]

    TimeEntry.visible_by(User.current) do
      respond_to do |format|
        format.api {
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

  def index_redmine14

    retrieve_date_range_14

    where = nil
    scope = TimeEntry.visible.spent_between(@from, @to)
    if @issue
      scope = scope.on_issue(@issue)
    elsif @project
      scope = scope.on_project(@project, Setting.display_subprojects_issues?)
    end

    if !params[:assigned_to_id].blank?
      where = ['user_id = ?', params[:assigned_to_id]]
    end

    respond_to do |format|
      format.api {
        @entry_count = scope.all(:conditions => where).count
        @offset, @limit = api_offset_and_limit
        @entries = scope.all(
          :include    => [:project, :activity, :user, {:issue => :tracker}],
          :conditions => where,
          :order      => sort_clause,
          :limit      => @limit,
          :offset     => @offset
        )
      }
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
      format.api {
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


  # Retrieves the date range based on predefined ranges or specific from/to param dates
  def retrieve_date_range_11
    @free_period = false
    @from, @to = nil, nil

    if params[:period_type] == '1' || (params[:period_type].nil? && !params[:period].nil?)
      case params[:period].to_s
      when 'today'
        @from = @to = Date.today
      when 'yesterday'
        @from = @to = Date.today - 1
      when 'current_week'
        @from = Date.today - (Date.today.cwday - 1)%7
        @to = @from + 6
      when 'last_week'
        @from = Date.today - 7 - (Date.today.cwday - 1)%7
        @to = @from + 6
      when '7_days'
        @from = Date.today - 7
        @to = Date.today
      when 'current_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1)
        @to = (@from >> 1) - 1
      when 'last_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1) << 1
        @to = (@from >> 1) - 1
      when '30_days'
        @from = Date.today - 30
        @to = Date.today
      when 'current_year'
        @from = Date.civil(Date.today.year, 1, 1)
        @to = Date.civil(Date.today.year, 12, 31)
      end
    elsif params[:period_type] == '2' || (params[:period_type].nil? && (!params[:from].nil? || !params[:to].nil?))
      begin; @from = params[:from].to_s.to_date unless params[:from].blank?; rescue; end
      begin; @to = params[:to].to_s.to_date unless params[:to].blank?; rescue; end
      @free_period = true
    else
      # default
    end
    
    @from, @to = @to, @from if @from && @to && @from > @to
    @from ||= (TimeEntry.earilest_date_for_project(@project) || Date.today)
    @to   ||= (TimeEntry.latest_date_for_project(@project) || Date.today)
  end


  # Retrieves the date range based on predefined ranges or specific from/to param dates
  def retrieve_date_range_14
    @free_period = false
    @from, @to = nil, nil

    if params[:period_type] == '1' || (params[:period_type].nil? && !params[:period].nil?)
      case params[:period].to_s
      when 'today'
        @from = @to = Date.today
      when 'yesterday'
        @from = @to = Date.today - 1
      when 'current_week'
        @from = Date.today - (Date.today.cwday - 1)%7
        @to = @from + 6
      when 'last_week'
        @from = Date.today - 7 - (Date.today.cwday - 1)%7
        @to = @from + 6
      when '7_days'
        @from = Date.today - 7
        @to = Date.today
      when 'current_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1)
        @to = (@from >> 1) - 1
      when 'last_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1) << 1
        @to = (@from >> 1) - 1
      when '30_days'
        @from = Date.today - 30
        @to = Date.today
      when 'current_year'
        @from = Date.civil(Date.today.year, 1, 1)
        @to = Date.civil(Date.today.year, 12, 31)
      end
    elsif params[:period_type] == '2' || (params[:period_type].nil? && (!params[:from].nil? || !params[:to].nil?))
      begin; @from = params[:from].to_s.to_date unless params[:from].blank?; rescue; end
      begin; @to = params[:to].to_s.to_date unless params[:to].blank?; rescue; end
      @free_period = true
    else
      # default
    end

    @from, @to = @to, @from if @from && @to && @from > @to
  end
end
