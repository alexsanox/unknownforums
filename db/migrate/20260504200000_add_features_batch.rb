class AddFeaturesBatch < ActiveRecord::Migration[8.1]
  def change
    # Email notification preferences on users
    add_column :users, :email_on_reply, :boolean, default: true, null: false
    add_column :users, :email_on_mention, :boolean, default: true, null: false

    # Maintenance mode (stored as a site setting)
    create_table :site_settings do |t|
      t.string  :key,   null: false
      t.text    :value
      t.timestamps
    end
    add_index :site_settings, :key, unique: true

    # Audit log
    create_table :audit_logs do |t|
      t.references :actor, foreign_key: { to_table: :users }, null: false
      t.string  :action,        null: false
      t.string  :target_type
      t.bigint  :target_id
      t.text    :details
      t.string :ip_address
      t.timestamps
    end
    add_index :audit_logs, %i[ target_type target_id ]
    add_index :audit_logs, :created_at

    # Download history
    create_table :download_histories do |t|
      t.references :user,       null: false, foreign_key: true
      t.references :attachment, null: false, foreign_key: true
      t.string :ip_address
      t.timestamps
    end
    add_index :download_histories, %i[ user_id attachment_id ]
    add_index :download_histories, :created_at

    # File comments
    create_table :file_comments do |t|
      t.references :attachment, null: false, foreign_key: true
      t.references :user,       null: false, foreign_key: true
      t.text    :body,          null: false
      t.integer :rating                       # 1-5, optional
      t.boolean :deleted, default: false, null: false
      t.timestamps
    end
    add_index :file_comments, [ :attachment_id, :deleted ]

    # File tags
    create_table :file_tags do |t|
      t.references :attachment, null: false, foreign_key: true
      t.string :tag, null: false
      t.timestamps
    end
    add_index :file_tags, [ :attachment_id, :tag ], unique: true
    add_index :file_tags, :tag

    # Trophies
    create_table :trophies do |t|
      t.references :user, null: false, foreign_key: true
      t.string :slug,    null: false
      t.string :name,    null: false
      t.string :description
      t.datetime :awarded_at, null: false
      t.timestamps
    end
    add_index :trophies, [ :user_id, :slug ], unique: true
  end
end
