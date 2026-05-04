class Admin::IpBansController < Admin::BaseController
  def index
    @ip_bans = IpBan.order(created_at: :desc).page(params[:page]).per(30)
  end

  def create
    @ip_ban = IpBan.new(ip_ban_params.merge(banned_by: current_user))
    if @ip_ban.save
      redirect_to admin_ip_bans_path, notice: "IP #{@ip_ban.ip_address} banned."
    else
      redirect_to admin_ip_bans_path, alert: @ip_ban.errors.full_messages.join(", ")
    end
  end

  def destroy
    IpBan.find(params[:id]).destroy
    redirect_to admin_ip_bans_path, notice: "IP ban removed."
  end

  private

  def ip_ban_params
    params.require(:ip_ban).permit(:ip_address, :reason, :expires_at)
  end
end
