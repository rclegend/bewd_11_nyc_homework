class Flight < ActiveRecord::Base
	belongs_to :user
	validates :flight_number, :departure_date, :departure_airport_code, presence: true

	def self.search(query)
    	where("flight_number LIKE :query OR departure_airport_code LIKE :query", query: "%#{query}%")
  	end
end
