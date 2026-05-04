class SpamDetector
  NEW_ACCOUNT_DAYS    = 7
  LINK_PATTERN        = %r{https?://}i
  MIN_POSTS_THRESHOLD = 3

  def self.check!(post)
    new(post).check!
  end

  def initialize(post)
    @post = post
    @user = post.user
  end

  def check!
    return if @user.can_moderate?
    return unless new_account?
    return unless contains_link?
    return if trusted_poster?

    flag_post!
  end

  private

  def new_account?
    @user.created_at > NEW_ACCOUNT_DAYS.days.ago
  end

  def contains_link?
    @post.body.match?(LINK_PATTERN)
  end

  def trusted_poster?
    @user.posts_count > MIN_POSTS_THRESHOLD
  end

  def flag_post!
    @user.update_columns(flagged: true, flag_reason: "Auto-flagged: new account posting links (spam detection)")
    Rails.logger.warn("SpamDetector: flagged user #{@user.id} (#{@user.username}) for post #{@post.id}")
  rescue => e
    Rails.logger.error("SpamDetector.flag_post! failed: #{e.message}")
  end
end
