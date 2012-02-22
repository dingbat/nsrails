class ApplicationController < ActionController::Base
  protect_from_forgery
  
  USER = "NSRails"
  PASSWORD = "iphone"

  before_filter :authenticate

  def authenticate
    authenticate_or_request_with_http_basic do |user_name, password|
      (user_name == USER && password == PASSWORD)
    end
  end
end
