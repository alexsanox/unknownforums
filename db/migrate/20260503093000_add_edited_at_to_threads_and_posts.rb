class AddEditedAtToThreadsAndPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :forum_threads, :edited_at, :datetime
    add_column :posts, :edited_at, :datetime
  end
end
