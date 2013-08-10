class AuthorizeController < ApplicationController
  def welcome
    if session[:user_id]
      @user = User.find session[:user_id]
    end
  end

  def auth
    json = HTTParty.post(
      "https://jawbone.com/auth/oauth2/token",
      :body => {
        :client_id => ENV["JAWBONE_CLIENT_ID"],
        :client_secret => ENV["JAWBONE_SECRET"],
        :grant_type => "authorization_code",
        :code => params[:code]
      }
    ).body
    token = JSON.parse(json)["access_token"]
    @user = User.find_by_token token
    unless @user
      @user = User.new(:token => token)
      user_info = HTTParty.get(
        "https://jawbone.com/nudge/api/users/@me",
        :headers => {
          "Authorization" => "Bearer #{token}"
          }
      )["data"]
      @user.first_name = user_info["first"]
      @user.last_name  = user_info["last"]
      @user.xid        = user_info["xid"]
      @user.photo      = user_info["image"]
      @user.save
      session[:user_id] = @user.id
    end
  end
end