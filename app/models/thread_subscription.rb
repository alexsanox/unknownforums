class ThreadSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :forum_thread

  def self.subscribe!(user:, thread:)
    find_or_create_by!(user: user, forum_thread: thread)
  end

  def self.unsubscribe!(user:, thread:)
    where(user: user, forum_thread: thread).destroy_all
  end

  def mark_read!
    update_column(:last_read_at, Time.current)
  end

  def unread?(thread)
    last_read_at.nil? || thread.posts.where("created_at > ?", last_read_at).exists?
  end
end
