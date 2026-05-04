class AddEmailOnThreadReplyToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_on_thread_reply, :boolean, default: true, null: false
  end
end
