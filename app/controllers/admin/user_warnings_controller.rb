class Admin::UserWarningsController < ApplicationController
  before_action :require_moderator
  before_action :set_user
  before_action :set_warning, only: %i[destroy]

  def create
    @warning = @user.warnings.build(warning_params.merge(warned_by: current_user))
    if @warning.save
      UserMailer.warning_notification(@user, @warning).deliver_later(queue: :mailers) if @user.email.present?
      AuditLog.record(actor: current_user, action: "warn_user", target: @user,
                      details: "Severity: #{@warning.severity}. Reason: #{@warning.reason}", ip: request.ip)
      redirect_to admin_user_path(@user), notice: "Warning issued."
    else
      redirect_to admin_user_path(@user), alert: @warning.errors.full_messages.join(", ")
    end
  end

  def destroy
    AuditLog.record(actor: current_user, action: "remove_warning", target: @user,
                    details: "Warning ID #{@warning.id} removed", ip: request.ip)
    @warning.destroy
    redirect_to admin_user_path(@user), notice: "Warning removed."
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_warning
    @warning = @user.warnings.find(params[:id])
  end

  def warning_params
    params.require(:user_warning).permit(:reason, :severity, :expires_at)
  end
end
