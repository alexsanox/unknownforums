class CreateIpBans < ActiveRecord::Migration[8.0]
  def change
    create_table :ip_bans do |t|
      t.string  :ip_address, null: false
      t.string  :reason
      t.bigint  :banned_by_id
      t.datetime :expires_at
      t.timestamps
    end
    add_index :ip_bans, :ip_address, unique: true
    add_index :ip_bans, :banned_by_id
  end
end
