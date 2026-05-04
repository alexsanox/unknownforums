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
    notify_thread_author
    notify_subscribers
    notify_mentions
  end

  private

  def notify_thread_author
    owner = @thread.user
    return if owner == @author
    return unless owner.email.present?
    return unless owner.email_on_thread_reply?
    return if @thread.subscribers.exists?(id: owner.id)

    Notification.notify!(
      recipient:  owner,
      actor:      @author,
      kind:       "subscription",
      notifiable: @post,
      message:    "#{@author.username} replied in your thread \"#{@thread.title.truncate(60)}\""
    )
    UserMailer.thread_reply_notification(owner, @post).deliver_later(queue: :mailers)
  end

  def notify_subscribers
    @thread.subscribers.where.not(id: @author.id).find_each do |subscriber|
      Notification.notify!(
        recipient:  subscriber,
        actor:      @author,
        kind:       "subscription",
        notifiable: @post,
        message:    "#{@author.username} replied in \"#{@thread.title.truncate(60)}\""
      )
      if subscriber.email_on_reply? && subscriber.email.present?
        UserMailer.thread_reply_notification(subscriber, @post).deliver_later(queue: :mailers)
      end
    end
  end

  MENTION_LIMIT = 5

  def notify_mentions
    mentioned_usernames = @post.body.scan(/@([A-Za-z0-9_\-]{3,30})/).flatten.uniq.first(MENTION_LIMIT)
    return if mentioned_usernames.empty?

    User.where(username: mentioned_usernames).where.not(id: @author.id).find_each do |user|
      Notification.notify!(
        recipient:  user,
        actor:      @author,
        kind:       "mention",
        notifiable: @post,
        message:    "#{@author.username} mentioned you in \"#{@thread.title.truncate(60)}\""
      )
      if user.email_on_mention? && user.email.present?
        UserMailer.mention_notification(user, @post).deliver_later(queue: :mailers)
      end
    end
  end
end
