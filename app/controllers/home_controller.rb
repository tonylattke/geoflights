class HomeController < ApplicationController
	def index
		request.headers['Access-Control-Allow-Origin'] = '*'
	end
end
