class FlightsController < ApplicationController
  def index
    @flights = current_user.flights
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
    @flight = Flight.find params[:id]
    @flight_date = Date.parse(@flight.departure_date.to_s)
  end
end
