class AddDetailstoFlights < ActiveRecord::Migration
  def change
  	  	add_column :flights, :flight_number, :string
  	  	add_column :flights, :departure_date, :date
  	  	add_column :flights, :departure_airport_code, :string
  end
end
