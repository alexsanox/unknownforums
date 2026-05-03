class ThreadSubscriptionsController < ApplicationController
  before_action :require_login
  before_action :set_thread

  def create
    ThreadSubscription.subscribe!(user: current_user, thread: @thread)
    redirect_back fallback_location: forum_thread_path(@thread), notice: "Watching this thread."
  end

  def destroy
    ThreadSubscription.unsubscribe!(user: current_user, thread: @thread)
    redirect_back fallback_location: forum_thread_path(@thread), notice: "Unwatched."
  end

  private

  def set_thread
    @thread = ForumThread.find(params[:forum_thread_id])
  end
end
