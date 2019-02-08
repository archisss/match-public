class ActivitiesController < ApplicationController
  def new
    if current_user.team.nil?
      redirect_to new_team_path
    else
      @activity = Activity.new
      @feedback = Feedback.new
      @locations = Location.all
      @selected_locations = []
    end
  end

  def create
    assing_instance_variables
    if @activity.save && assign_locations_string && assign_activity_points
      flash[:notice] = t('activities.messages.uploaded')
      redirect_to team_path(current_user.team)
    else
      flash[:alert] = t('activities.messages.error_creating')
      render 'new'
    end
  end

  def show
    @activity = Activity.find(params[:id])
    user_has_permissions
    @feedback = Feedback.new
  end

  def destroy
    @activity = Activity.find_by(id: params[:id])
    if user_can_destroy_activity 
      if @activity.destroy
        flash[:notice] = t('activities.messages.deleted')
        redirect_to team_path(current_user.team)
      else
        flash[:alert] = t('activities.messagess.erorr_deleting')
        render 'index'
      end
    else
      flash[:alert] = t('activities.messagess.erorr_deleting')
    end
  end

  def edit
    @activity = Activity.find_by(id: params[:id])
    redirect_to main_index_path unless user_can_edit_activity
    @locations = Location.all
    @selected_locations = @activity.locations
    @filename = @activity.activity_file.url ? File.basename(@activity.activity_file&.url) : nil
  end

  def update
    @activity = Activity.find_by(id: params[:id])
    if @activity.update(activity_params)
      assign_locations_string
      assign_activity_points
      flash[:notice] = t('activities.messages.updated')
      redirect_to team_path(current_user.team.id)
    else
      flash[:notice] = t('activities.messages.error_updating')
      render 'edit'
    end
  end

  private

  def assign_locations_string
    @selected_locations = params[:locations_string]
    @activity.locations.destroy_all
    @selected_locations.split('ß').each do |location_name|
      @activity.locations << Location.create(name: location_name)
    end
  end

  def assign_activity_points
    obtain_activity_points
    @activity.update_attribute(:score, @activity.score)
    current_user.role == 'judge' ? vote_for_activity : true
  end

  def obtain_activity_points
    @activity.score = 40 if @activity.activity_type == 'Curso'
    @activity.score = 25 if @activity.activity_type == 'Plática'
    @activity.score = 10 if @activity.activity_type == 'Post'
  end

  def activity_params
    params.require(:activity).permit(:name, :english, :location,
                                     :activity_type, :locations_string,
                                     :description, :pitch_audience,
                                     :abstract_outline, :notes, :activity_file)
  end

  def user_has_permissions
    redirect_to root_path if current_user.team.id != @activity.user.team&.id
  end

  def assing_instance_variables
    @locations = Location.all
    @activity = Activity.new(activity_params)
    @activity.user_id = current_user.id
  end

  def vote_for_activity
    activity_statuses = ActivityStatus.new(activity_id: @activity.id, user_id: current_user.id, approve: true)
    activity_statuses.save
  end
  
  def user_can_destroy_activity
    @activity.status != 'Aprobado'
  end

  def user_can_edit_activity
    @activity.status != 'Aprobado'
  end
end
