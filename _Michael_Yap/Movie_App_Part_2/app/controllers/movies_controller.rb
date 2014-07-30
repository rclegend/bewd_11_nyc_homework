class MoviesController < ApplicationController
  def index
  	@movies = Movie.all
  	# Watch how you pluralizes instance variables.
  	# The plural makes sense here because it contains all movies.
  end

  def edit
  	@movie = Movie.find(params[:id])
  end

  def update
  	@movie = Movie.find(params[:id])

  	if @movie.update(movie_params)
  		redirect_to @movie
  	else
  		render "edit"
  	end

  	# The method update, is used when you want to update a record that already exists. It accepts a hash containing the attributes that you want to update.

  end

  def create
  end


  def show
  	@movie = Movie.find(params[:id])
  end

  private
  	def movie_params
  		params.require(:movie).permit(:title, :description)
  	end

end
