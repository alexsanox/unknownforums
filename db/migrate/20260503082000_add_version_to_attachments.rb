class AddVersionToAttachments < ActiveRecord::Migration[8.1]
  def change
    add_column :attachments, :version,              :integer, default: 1, null: false
    add_column :attachments, :parent_attachment_id, :bigint
    add_index  :attachments, :parent_attachment_id
  end
end
