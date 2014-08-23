class FlightsController < ApplicationController
  def index
    if user_signed_in?
      @flights = current_user.flights
    else
      redirect_to root_path
    end
  end

  def new
    @flight = Flight.new
  end

  def create
    safe_flight_params = params.require(:flight).permit(:flight_number, :departure_date, :departure_airport_code)
    @flight = current_user.flights.build safe_flight_params

    if @flight.save
      redirect_to @flight
    else
      render :new
    end
  end

  def edit
  	@flight = Flight.find params[:id]
  end

  def update
  	@flight = current_user.flights.find params[:id]
  	@flight.update params.require(:flight).permit(:flight_number, :departure_date, :departure_airport_code)
    redirect_to @flight  
  end

  def show
    # Get current location
    get_current_location

    # Load the flight data using parameters
    if is_params_ready
      load_flight_data
      get_directions(@commute_mode,@arrival_time,@origin_location,@departure_airport_name)
    else
      @has_flightstatus_error = true
      @flightstatus_error_msg = "Required fields not completed"
    end
    @flight = Flight.find params[:id]
    @flight_date = Date.parse(@flight.departure_date.to_s)
  end

  def destroy
    @flight = Flight.find params[:id]
    @flight.destroy
    redirect_to flights_path
  end 
end
