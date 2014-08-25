class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  	# Initialize
  	require 'json'
  	require 'rest-client'
  	require 'date'
  	require "erb"
  	include ERB::Util
  	require 'open-uri'

  	def index
  	end

  	def is_params_ready
  		if params[:flight_number]=="" || params[:date]=="" || params[:risk_profile]==nil || params[:departure_airport_code]=="" || params[:origin_location]==nil
  			return false
  		else
  			return true
  		end
  	end

  	def load_flight_data
		# Error flags
		@has_flightstatus_error = false
		@flightstatus_error_msg = ""
		@has_directions_error = false
		@directions_error_msg = ""

		# Get Flight number
		@flight_code = params[:flight_number]
		carrier = @flight_code[0,2]
		flight_number = @flight_code[2,@flight_code.length-1]

		# Get Departure Date
		departure_date = params[:date]
		departure_year = departure_date[0,4]
		departure_month = departure_date[5..6]
		departure_day = departure_date[8..9]

		# Get risk preference
		risk_profile = params[:risk_profile]

		# Departure airport
		departure_airport_code = params[:departure_airport_code]

		# Origin Location
		@origin_location = params[:origin_location]

		# Commute Mode
		@commute_mode = params[:commute_mode]
		if @commute_mode == 'Public Transit'
			@commute_mode = 'transit'
		elsif @commute_mode == 'Walking'
			@commute_mode = 'walking'
		else
			@commute_mode = 'driving'
		end

		# Do you have baggage?
		has_baggage = params[:baggage_to_checkin]
		if has_baggage == "Y"
			has_baggage = true
		else
			has_baggage = false
		end

		# Look up flight number, and corresponding airport (FlightStats)
		flight_status_url = "https://api.flightstats.com/flex/flightstatus/rest/v2/json/flight/status/#{carrier}/#{flight_number}/dep/#{departure_year}/#{departure_month}/#{departure_day}?appId=b0b4e066&appKey=e9b284bee6cd5931f3af074eb4072baf&utc=true&airport=#{departure_airport_code}"
		flightstats_client = RestClient.get(flight_status_url)
		flightstats_json = JSON.load(flightstats_client)

		# Check if request was bad
		if flightstats_json.has_key?("error")
			@flightstatus_error_msg = flightstats_json["error"]["errorMessage"]
			@has_flightstatus_error = true
		elsif flightstats_json["flightStatuses"].empty?
		# Check if flight status is available
		@flightstatus_error_msg = "Flight Status Not Available"
		@has_flightstatus_error = true
	else
			# No problems - continue on
			# Return the departure airport name (or address)
			departure_airport_code = flightstats_json["flightStatuses"].first["departureAirportFsCode"]
			departure_airport_array = flightstats_json["appendix"]["airports"].select {|airport| airport["fs"] == departure_airport_code }
			@departure_airport_name = departure_airport_array.first["name"]
			@departure_airport_latitude = departure_airport_array.first["latitude"]
			@departure_airport_longitude = departure_airport_array.first["longitude"]
			@departure_airport_terminal = flightstats_json["flightStatuses"].first["airportResources"]["departureTerminal"]

			# Determine if flight is an international flight or domestic flight
			airport_countries = []
			international_flight = false
			flightstats_json["appendix"]["airports"].each do |airport|
				airport_countries << airport["countryCode"]
			end
			airport_countries.each do |country|
				if country != airport_countries.first
					international_flight = true
				end
			end

			# Return the flight departure time
			@departure_flight_datetime = DateTime.iso8601(flightstats_json["flightStatuses"].first["departureDate"]["dateLocal"])

			# Return flight status
			# - Scheduled (S) - A scheduled flight is one that is anticipated to depart and arrive according to either filed flight plans or published flight schedules. A Scheduled flight can transition to Cancelled, Active, or Unknown.
			# - Active (A) - Active flights represent pushed back from gate and airborne flights. They may have departure information depending upon the availability of the data. An active flight may transition to Unknown, Landed, or Redirected. While active, FlightStats tracks information about departure, estimated arrival, and where available, positional data.
			# - Unknown (U) - An unknown flight occurs when FlightStats cannot determine the final status of a flight from a data source in a reasonable amount of time. Note, this is a valid state rather than an error state. For example, ASDI information may not be available for certain flights internationally or the airline may not participate in a subscribed GDS.
			# - Redirected (R) - The flight is in the air and has changed its destination to an unscheduled airport. After landing at an unscheduled airport, the state will change to Diverted.
			# - Landed (L) - The flight landed at the scheduled airport.
			# - Diverted (D) - The flight landed at an unscheduled airport.
			# - Cancelled (C) - The flight was cancelled.
			# - Not Operational (NO) - The flight appears to be from an outdated schedule or flight plan – meaning that when we queried the airline, it returned that the flight is not scheduled.
			@departure_flight_status = flightstats_json["flightStatuses"].first["status"]
			case flightstats_json["flightStatuses"].first["status"]
			when 'S'
			  @departure_flight_status = "<span class=\"label label-success\">Scheduled</span>"
			when 'A'
			  @departure_flight_status = "<span class=\"label label-success\">Active</span>"
			when 'U'
			  @departure_flight_status = "<span class=\"label label-warning\">Unknown</span>"
			when 'R'
			  @departure_flight_status = "<span class=\"label label-warning\">Redirected</span>"
			when 'L'
			  @departure_flight_status = "<span class=\"label label-success\">Landed</span>"
			when 'D'
			  @departure_flight_status = "<span class=\"label label-warning\">Diverted</span>"
			when 'C'
			  @departure_flight_status = "<span class=\"label label-danger\">Cancelled</span>"
			else
			  @departure_flight_status = "<span class=\"label label-primary\">Not Found</span>"
			end

			# For the risk preference, calculate the time required prior to boarding to be at the airport
			# For international flights (High Risk: T-90min, Medium: T-120min, Low: T-180min)
			# For domestic flights w/ baggage (High Risk: T-20min, Medium: T-45min, Low: T-60min)
			# For domestic flights w/o baggage (High Risk: T-10min, Medium: T-30min, Low: T-45min)
			# Return the date/time required to be at the airport
			# Date Format: 2000-01-02T00:00:00Z
			checkin_time = DateTime.new
			if international_flight
				if risk_profile == "High"
					checkin_time = @departure_flight_datetime - Rational(5400, 86400)
				elsif risk_profile == "Medium"
					checkin_time = @departure_flight_datetime - Rational(7200, 86400)
				else
					#Low Risk
					checkin_time = @departure_flight_datetime - Rational(10800, 86400)
				end
			else 
			# Domestic flight
			if has_baggage
				if risk_profile == "High"
					checkin_time = @departure_flight_datetime - Rational(1200, 86400)
				elsif risk_profile == "Medium"
					checkin_time = @departure_flight_datetime - Rational(2700, 86400)
				else
						#Low Risk
						checkin_time = @departure_flight_datetime - Rational(3600, 86400)
					end
				else
					#No baggage
					if risk_profile == "High"
						checkin_time = @departure_flight_datetime - Rational(600, 86400)
					elsif risk_profile == "Medium"
						checkin_time = @departure_flight_datetime - Rational(1800, 86400)
					else
						#Low Risk
						checkin_time = @departure_flight_datetime - Rational(2700, 86400)
					end
				end
			end
			@arrival_time = checkin_time.strftime("%s")
		end

	end

	def get_directions(commute_mode,arrival_time,origin_location,departure_airport_name)

		# Load directions from Google API
		directions_url = "https://maps.googleapis.com/maps/api/directions/json?origin=#{url_encode(origin_location)}&destination=#{url_encode(departure_airport_name)}&arrival_time=#{arrival_time}&mode=#{commute_mode}&key=AIzaSyA7KOsivxHiRaAOhXcRod0ol87SMBrGRyQ".force_encoding('ASCII-8BIT')
		# @encoded_dir_url = URI.encode(directions_url.strip)
		# @encoded_dir_url= URI.parse(@encoded_dir_url)
		# encoded_dir_url = URI::encode(directions_url)
		directions_client = RestClient.get(directions_url)
		directions_json = JSON.load(directions_client)

		# Error flags
		@has_directions_error = false
		@directions_error_msg = ""

		# Google Maps URL
		@gmaps_url = "https://www.google.com/maps/embed/v1/directions?key=AIzaSyA7KOsivxHiRaAOhXcRod0ol87SMBrGRyQ&origin=#{url_encode(origin_location)}&destination=#{url_encode(departure_airport_name)}&mode=#{commute_mode}"

		# Check if request is bad
		if directions_json["status"] != "OK"
			@has_directions_error = true
			@directions_error_msg = "Directions not found: #{directions_json["status"]}"
		else
			# Request is good
			@departure_time = arrival_time.to_i - directions_json["routes"].first["legs"].first["duration"]["value"]
			@departure_time = DateTime.strptime(@departure_time.to_s,'%s')
			@arrival_time = DateTime.strptime(@arrival_time.to_s,'%s')
			# Print out the departure time
			# puts "By #{commute_mode}: You need to leave at #{DateTime.strptime(departure_time.to_s,'%s')} in order to check-in at #{departure_airport_name} by #{DateTime.strptime(arrival_time.to_s,'%s')}"
			# Print out the directions
			# puts "Directions: "
			# puts "-------------------------------------------"
			@directions = directions_json["routes"].first["legs"].first["steps"]
			# directions_json["routes"].first["legs"].first["steps"].each_with_index do |steps, index|
			# puts "#{index+1}: #{steps["html_instructions"]} [Distance: #{steps["distance"]["text"]}] [Duration: #{steps["duration"]["text"]}]"
			# end
		end
	end

	def get_current_location
		currentloc_client = RestClient.get("http://freegeoip.net/json/")
		currentloc_json = JSON.load(currentloc_client)
		@current_location = "#{currentloc_json["city"]}, #{currentloc_json["region_name"]}, #{currentloc_json["country_name"]}"
	end
end
