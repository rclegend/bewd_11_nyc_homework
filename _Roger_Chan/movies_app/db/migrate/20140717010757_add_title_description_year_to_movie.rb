class AddTitleDescriptionYearToMovie < ActiveRecord::Migration
  def change
	add_column :movies, :title, :string
	add_column :movies, :description, :string
	add_column :movies, :year_released, :string
  end
end
