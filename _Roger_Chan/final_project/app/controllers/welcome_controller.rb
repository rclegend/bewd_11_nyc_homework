class WelcomeController < ApplicationController

	def index
		# Get current location
		get_current_location
	end

	def show
		if is_params_ready
			load_flight_data
			get_directions(@commute_mode,@arrival_time,@origin_location,@departure_airport_name)
		else
			flash[:error] = "Required fields not completed"
			redirect_to root_path
		end
	end

end
