class Admin::SiteSettingsController < ApplicationController
  before_action :require_admin

  def index
    @maintenance = SiteSetting.maintenance_mode?
    @maintenance_message = SiteSetting.maintenance_message
  end

  def update
    SiteSetting.set(SiteSetting::MAINTENANCE_KEY, params[:maintenance_mode] == "1" ? "true" : "false")
    SiteSetting.set(SiteSetting::MAINTENANCE_MESSAGE_KEY, params[:maintenance_message].to_s.strip)
    redirect_to admin_site_settings_path, notice: "Settings saved."
  end
end
