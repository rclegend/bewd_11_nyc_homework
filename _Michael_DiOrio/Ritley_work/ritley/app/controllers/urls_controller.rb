class UrlsController < ApplicationController

  def index
  	@urls= Url.all
  	@count = 1
  end

  def show
    @url = Url.find(params[:id])
    @full_path = "#{request.protocol}#{request.host_with_port}/#{@url.code}"
	end

  def new
  	@url= Url.new
  end

  def edit
  	@url = Url.find(params[:id])
  end

  def create
  	@url = Url.new(url_params)
  	@url.code = rand(1..1000000)
  	if @url.save
    	redirect_to @url
  	else
    	render 'new'
    end

  	# @url.save
  	# redirect_to @url
  end

  def update
  	@url= Url.find(params[:id])
 
  	if @url.update(url_params)
    	redirect_to @url
  	else
    	render 'edit'
  	end
	end

def redirector
     @url = Url.find_by code: params[:code2]
     if @url
       redirect_to @url.link
     else
       redirect_to root_path
     end
   end
 
   def preview
     @url = Url.find_by code: params[:code2]
     unless @url
       redirect_to root_path
     end
   end


  private
  def url_params
    params.require(:url).permit(:link, :code)
  end

  # def hashiness
  # 	@hash_code= rand(10..15)
  # end

 end