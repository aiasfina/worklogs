class WorklogsController < ApplicationController
  model_object Worklog
  unloadable
  
  before_action :find_model_object, except: [:index, :new, :create,:my,:preview]
  before_action :init_slider, only: [:index, :my, :new, :edit, :show]
  
  def index
    load_worklogs(**params.symbolize_keys)
  end

  def preview
    # where is the visible method?
    @previewed = Worklog.find_by(id: params[:id])

    @worklog = Worklog.new(worklog_params)
    @worklog.day = Date.today
    @worklog.week = Date.today.strftime("%W").to_i
    @worklog.author = User.current

    render partial: 'preview'
  end

  def my
    load_worklogs(user_id: session[:user_id], week: params[:week])
    render :index
  end

  def new
    @day = Time.zone.today
    @day_todo = Worklog.where("user_id = ? and day <> ? and typee = ?", session[:user_id],Date.today,0).last
    @week_todo = Worklog.where("user_id = ? and day <> ? and typee = ?", session[:user_id],Date.today,1).last
    @month_todo = Worklog.where("user_id = ? and day <> ? and typee = ?", session[:user_id],Date.today,2).last
    @year_todo = Worklog.where("user_id = ? and day <> ? and typee = ?", session[:user_id],Date.today,3).last

    @worklog = Worklog.new(typee: 1)
  end

  def edit
    @day = Date.today
    @day_todo = Worklog.where("user_id = ? and day <> ? and typee = ?", session[:user_id],Date.today,0).last
    @week_todo = Worklog.where("user_id = ? and day <> ? and typee = ?", session[:user_id],Date.today,1).last
  end

  def show
    @worklog_reviews = @worklog.worklog_reviews
    @worklog_review = WorklogReview.new
  end

  def review
    @worklog_reviews = @worklog.worklog_reviews.build params[:worklog_review]
    @worklog_reviews.user = User.current

    if @worklog_reviews.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to worklog_url(@worklog)
    end
  end

  def update
    @worklog.update worklog_params
    # why check request method here?
    if request.put? and @worklog.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to worklogs_url
    else
      render :edit
    end
  end
  
  def create
    @worklog = Worklog.new worklog_params

    if @worklog.save
      redirect_to worklogs_url
    end
  end

  protected
  def worklog_params
    params.require(:worklog).permit(:typee, :do, :todo, :feel, :score, :good, :nogood)
  end

  def load_worklogs(user_id: nil, week: nil, typee: nil, **_)
    worklogs_scope = Worklog.punctual

    worklogs_scope =
      case true
      when user_id.present?
        worklogs_scope.where(user_id: user_id)
      when week.present?
        worklogs_scope.where(week: week)
      when typee.present?
        worklogs_scope.where(typee: typee)
      else
        worklogs_scope
      end.order(day: :desc, id: :desc)

    @worklogs_pages = Paginator.new worklogs_scope.count, Worklog.pagination_limit, params['page']
    @worklogs = worklogs_scope
      .order(created_at: :desc)
      .offset(@offset || @worklogs_pages.offset)
      .limit(Worklog.pagination_limit)
  end

  def init_slider
    @last = Worklog.lastest_created_time
    @start = Time.zone.today
    @users =  User.logged.status(1).order(id: :asc) - Worklog.no_need_users
  end
end
