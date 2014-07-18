class MoviesController < ApplicationController
	def index
	end

	def get_movies
		movies = Movie.all
	end
	helper_method :get_movies
end
