class AddUserAssociationToFlights < ActiveRecord::Migration
  def change
  	    add_reference :flights, :user, index: true
  end
end
