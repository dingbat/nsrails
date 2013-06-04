class HomeController < ApplicationController
  def authenticate
    true
  end

  def auth_error
  	render status:401, json: {message:"Test string"}
  end
end
