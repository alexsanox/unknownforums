class Admin::AuditLogsController < ApplicationController
  before_action :require_moderator

  def index
    @logs = AuditLog.includes(:actor).recent
    @logs = @logs.where(action: params[:action_filter]) if params[:action_filter].present?
    @logs = @logs.where(actor_id: params[:actor_id]) if params[:actor_id].present?
    @logs = @logs.page(params[:page]).per(50)
  end
end
