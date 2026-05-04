class NotificationsController < ApplicationController
  before_action :require_login

  def index
    @mentions = current_user.notifications
                            .where(kind: "mention")
                            .includes(:actor, :notifiable)
                            .recent
                            .limit(30)

    @watched_threads = current_user.thread_subscriptions
                                   .includes(forum_thread: [ :subforum, :user ])
                                   .order(updated_at: :desc)
                                   .limit(30)

    current_user.notifications.unread.update_all(read: true)
    current_user.bust_notification_cache
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read: true)
    current_user.bust_notification_cache
    redirect_to notifications_path, notice: "All notifications marked as read."
  end
end
