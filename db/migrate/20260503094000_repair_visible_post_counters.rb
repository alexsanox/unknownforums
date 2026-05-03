class RepairVisiblePostCounters < ActiveRecord::Migration[8.1]
  def up
    ForumThread.reset_column_information
    Subforum.reset_column_information
    User.reset_column_information

    ForumThread.find_each do |thread|
      thread.update_columns(posts_count: Post.where(forum_thread_id: thread.id, deleted: false).count)
    end

    Subforum.find_each do |subforum|
      count = Post.joins(:thread).where(forum_threads: { subforum_id: subforum.id }, deleted: false).count
      subforum.update_columns(posts_count: count)
    end

    User.find_each do |user|
      user.update_columns(posts_count: Post.where(user_id: user.id, deleted: false).count)
    end
  end

  def down
  end
end
