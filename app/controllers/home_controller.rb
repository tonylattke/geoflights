class HomeController < ApplicationController
	def index
		request.headers['Access-Control-Allow-Origin'] = '*'
	end

	def countries
		
	end

	def connections_airports
		@route = params[:route]

		@airport_id = params[:id]
		@airport_name = params[:name]
		@airport_latitude = params[:latitude]
		@airport_longitude = params[:longitude]
	end

	def airline_airports
		@airline_id = params[:id]
		@airline_name = params[:name]
	end
end
