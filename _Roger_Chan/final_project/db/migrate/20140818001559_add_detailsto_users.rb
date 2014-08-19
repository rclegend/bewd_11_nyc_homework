class AddDetailstoUsers < ActiveRecord::Migration
  def change
  	add_column :users, :home_address, :string
  	add_column :users, :office_address, :string
  	add_column :users, :risk_profile, :string
  	add_column :users, :commute_mode, :string
  end
end
