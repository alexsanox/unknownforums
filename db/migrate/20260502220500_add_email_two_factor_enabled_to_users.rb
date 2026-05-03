class AddEmailTwoFactorEnabledToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_two_factor_enabled, :boolean, default: false, null: false
    add_index :users, :email_two_factor_enabled
  end
end
