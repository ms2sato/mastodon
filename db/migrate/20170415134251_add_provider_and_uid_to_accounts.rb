class AddProviderAndUidToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :provider, :string
    add_column :accounts, :uid, :string
    add_column :accounts, :token, :string
  end
end
