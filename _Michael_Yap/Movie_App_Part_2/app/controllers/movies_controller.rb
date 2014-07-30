class MoviesController < ApplicationController
  def index
  	@movies = Movie.all
  end

  def edit
  	@movie = Movie.find(params[:id])
  end

  def update
  end

  def create
  end


  def show
  	@movie = Movie.find(params[:id])
  end



end
