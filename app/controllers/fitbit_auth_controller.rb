class FitbitAuthController < ApplicationController
  
  def index
    @users = User.all
  end

  # this is the callback information from fitbit
  def get_response
    # Access Credentials
    oauth_token = params[:oauth_token]
    oauth_verifier = params[:oauth_verifier]

    # creates a variable we can pass as an argument below
    data = request.env['omniauth.auth']

    # the data we'll be receiving, activity data
    activities = get_user_activities(data)
    # our view will render a basic json object  
    render json:activities
    #activities is an object
  end

private
  # this is the information we're sending to fitbit
  def get_user_activities(data)
    fitbit_user_id = data["uid"]

    user_secret = data["credentials"]["secret"]
    user_token = data["credentials"]["token"]

    
    # creates a new instance of Fitgem
    client = Fitgem::Client.new({
      consumer_key: '95ecbb851b8165022e445ff61c5248e5',
      consumer_secret: '58bafd75ecc502521569c8613d6ca33d',
      token: user_token,
      secret: user_secret,
      user_id: fitbit_user_id,
    })
    # Reconnects existing user using their credentials
    access_token = client.reconnect(user_token, user_secret)
    newuser = User.find_or_initialize_by(:uid => fitbit_user_id)
    profile = User.user_info()
    profile_json = json:profile
    newuser.update_attributes(:gender => profile["user"]["gender"], :dob => profile["user"]["dateOfBirth"] )
    # specifies date range to request data from
    # client.activities_on_date('today')
    client.sleep_on_date('2015-10-25')
  end
end