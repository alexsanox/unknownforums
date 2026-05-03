class NotificationDispatcher
  def self.dispatch_for_post(post)
    new(post).dispatch
  end

  def initialize(post)
    @post   = post
    @thread = post.thread
    @author = post.user
  end

  def dispatch
    notify_subscribers
    notify_mentions
  end

  private

  def notify_subscribers
    @thread.subscribers.where.not(id: @author.id).find_each do |subscriber|
      Notification.notify!(
        recipient:  subscriber,
        actor:      @author,
        kind:       "subscription",
        notifiable: @post,
        message:    "#{@author.username} replied in \"#{@thread.title.truncate(60)}\""
      )
    end
  end

  def notify_mentions
    mentioned_usernames = @post.body.scan(/@([A-Za-z0-9_\-]{3,30})/).flatten.uniq
    return if mentioned_usernames.empty?

    User.where(username: mentioned_usernames).where.not(id: @author.id).find_each do |user|
      Notification.notify!(
        recipient:  user,
        actor:      @author,
        kind:       "mention",
        notifiable: @post,
        message:    "#{@author.username} mentioned you in \"#{@thread.title.truncate(60)}\""
      )
    end
  end
end
