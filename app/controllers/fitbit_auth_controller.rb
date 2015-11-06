class FitbitAuthController < ApplicationController
 
  def index
    users = User.all
    @usernames = []
    users.each do |u|
      @usernames.push(u[:username])
    end
  end

  def dashboard
    users = User.all
    uids=[]
    users.each do |u|
      uids.push(u[:uid])
    end
    uid = uids[params[:index].to_i]
    @user = User.find_by(:uid => uid)
    @sleepChart = create_sleep_chart(uid)
    @activityChart = create_activity_chart(uid)
  end

  # this is the callback information from fitbit
  def get_response
    # Access Credentials
    oauth_token = params[:oauth_token]
    oauth_verifier = params[:oauth_verifier]

    # creates a variable we can pass as an argument below
    data = request.env['omniauth.auth']

    dates = ["2015-11-02", "2015-11-03", "2015-11-04", "2015-11-05", "2015-11-06"]
    dates.each do |d|
      get_user_activities(data, d)
    end
  end

private
  # this is the information we're sending to fitbit
  def get_user_activities(data, date)
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
    profile = client.user_info()
    newuser.update_attributes(:username => profile["user"]["displayName"], :gender => profile["user"]["gender"], :dob => profile["user"]["dateOfBirth"] )
    
    record = Sleep.find_or_initialize_by(:uid => fitbit_user_id, :date => date)
    sleepinfo = client.sleep_on_date(date)
    unless sleepinfo["sleep"].nil?
      sleepinfo["sleep"].each do |s|
        if s["isMainSleep"] == true
          record.update_attributes(:minutesToFallAsleep => s["minutesToFallAsleep"], :awakeDuration => s["awakeDuration"], :awakeningsCount => s["awakeCount"], :totalMinutesAsleep => s["minutesAsleep"], :totalTimeInBed => s["timeInBed"], :startTime => s["startTime"])
        end
      end
    end

    act_record = Activity.find_or_initialize_by(:uid => fitbit_user_id, :date => date)
    activitiesinfo = client.activities_on_date(date)
    unless activitiesinfo["summary"].nil?
      act_record.update_attributes(:steps => activitiesinfo["summary"]["steps"], :failyActiveMinutes => activitiesinfo["summary"]["failyActiveMinutes"], :lightlyActiveMinutes => activitiesinfo["summary"]["lightlyActiveMinutes"], :sedentaryMinutes => activitiesinfo["summary"]["sedentaryMinutes"], :veryActiveMinutes => activitiesinfo["summary"]["veryActiveMinutes"])
    end
  end

  def create_sleep_chart(uid)
    sleeps = Sleep.where(:uid => uid)
    datetime = []
    awakeDurations = []
    awakeningsCounts = []
    minutesToFallAsleeps =[]
    totalMinutesAsleeps = []
    totalMinutesInBeds = []
    sleeps.each do |s|
      datetime.push(s[:date]+" "+s[:startTime][11..-5]+"AM")
      awakeDurations.push(s[:awakeDuration])
      awakeningsCounts.push(s[:awakeningsCounts])
      minutesToFallAsleeps.push(s[:minutesToFallAsleep])
      totalMinutesAsleeps.push(s[:totalMinutesAsleep])
      totalMinutesInBeds.push(s[:totalTimeInBed])
    end
    @chart = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(:text => "Sleep summary")
      f.xAxis(:categories => datetime)
      f.series(:name => "minutes to fall asleep", :yAxis => 0, :data => minutesToFallAsleeps)
      f.series(:name => "awake times", :yAxis => 1, :data => awakeDurations)
      f.yAxis [
        {:title => {:text => "Minutes to Fall Asleep", :margin => 20} },
        {:title => {:text => "Awake Times"}, :opposite => true},
      ]

      f.legend(:align => 'center', :verticalAlign => 'bottom', :layout => 'horizontal',)
      f.chart({:defaultSeriesType=>"spline"})
    end
    return @chart    
  end

  def create_activity_chart(uid)
    activities = Activity.where(:uid => uid)
    dates = []
    steps = []
    sedentaryMinutes = []
    activities.each do |a|
      dates.push(a[:date])
      steps.push(a[:steps])
      sedentaryMinutes.push(a[:sedentaryMinutes])
    end
    @chart = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(:text => "Activity summary")
      f.xAxis(:categories => dates)
      f.series(:name => "steps", :yAxis => 0, :data => steps)
      f.series(:name => "sedentary Minutes", :yAxis => 1, :data => sedentaryMinutes)
      f.yAxis [
        {:title => {:text => "Total steps", :margin => 20} },
        {:title => {:text => "Total sedentary minutes"}, :opposite => true},
      ]

      f.legend(:align => 'center', :verticalAlign => 'bottom', :layout => 'horizontal',)
      f.chart({:defaultSeriesType=>"column"})
    end
    return @chart    
  end
end