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

  def unread?(thread = forum_thread)
    last_read_at.nil? || (thread.posts.maximum(:created_at)&.> last_read_at)
  end

  def unread_count(thread = forum_thread)
    return 0 unless last_read_at.nil? || unread?(thread)
    last_read_at.nil? ? thread.posts_count : thread.posts.where("created_at > ?", last_read_at).count
  end

  def self.unread_map_for(user, thread_ids)
    where(user: user, forum_thread_id: thread_ids)
      .index_by(&:forum_thread_id)
  end
end
