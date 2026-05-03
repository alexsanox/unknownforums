class NotificationsController < ApplicationController
  before_action :require_login

  def index
    @notifications = current_user.notifications.includes(:actor).recent.limit(50)
    current_user.notifications.unread.update_all(read: true)
  end
end
