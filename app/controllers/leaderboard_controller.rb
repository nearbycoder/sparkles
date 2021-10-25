class LeaderboardController < ApplicationController
  before_action :require_authentication

  def show
    @high_score = User.maximum(:sparkles_count)
    @users = User.order(sparkles_count: :desc).page(params[:page]).per(100)
  end

  def details
    raise ActiveRecord::RecordNotFound unless current_team.id == params[:team_id]

    @user = current_team.users.find(params[:user_id])
    @sparkles = @user.sparkles.includes(:sparkler, :channel).order(created_at: :desc).page(params[:page]).per(25)
  end
end
