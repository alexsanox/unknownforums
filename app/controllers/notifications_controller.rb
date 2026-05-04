class NotificationsController < ApplicationController
  before_action :require_login

  def index
    @mentions = current_user.notifications
                            .where(kind: [ "mention", "subscription" ])
                            .includes(:actor, :notifiable)
                            .recent
                            .page(params[:page]).per(20)

    @watched_threads = current_user.thread_subscriptions
                                   .includes(forum_thread: [ :subforum, :user ])
                                   .order(updated_at: :desc)
                                   .page(params[:watched_page]).per(20)

    current_user.notifications.unread.update_all(read: true)
    current_user.bust_notification_cache
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read: true)
    current_user.bust_notification_cache
    redirect_to notifications_path, notice: "All notifications marked as read."
  end
end
