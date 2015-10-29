class FitbitAuthController < ApplicationController
  
  def index
    users = User.all
    sleeps = Sleep.all
    activities = Activity.all
    @usernames = []
    @sleepCharts = []
    @activityCharts = []
    @chart2 = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(:text => "Population vs GDP For 5 Big Countries [2009]")
      f.xAxis(:categories => ["United States", "Japan", "China", "Germany", "France"])
      f.series(:name => "GDP in Billions", :yAxis => 0, :data => [14119, 5068, 4985, 3339, 2656])
      f.series(:name => "Population in Millions", :yAxis => 1, :data => [310, 127, 1340, 81, 65])

      f.yAxis [
        {:title => {:text => "GDP in Billions", :margin => 70} },
        {:title => {:text => "Population in Millions"}, :opposite => true},
      ]

      f.legend(:align => 'right', :verticalAlign => 'top', :y => 75, :x => -50, :layout => 'vertical',)
      f.chart({:defaultSeriesType=>"column"})
    end
    users.each do |u|
      @usernames.push(u[:username])
      sc = create_sleep_chart(u[:uid])
      @sleepCharts.push(sc)
      sa = create_activity_chart(u[:uid])
      @activityCharts.push(sa)
    end
  end

  # this is the callback information from fitbit
  def get_response
    # Access Credentials
    oauth_token = params[:oauth_token]
    oauth_verifier = params[:oauth_verifier]

    # creates a variable we can pass as an argument below
    data = request.env['omniauth.auth']

    # the data we'll be receiving, activity data
    get_user_activities(data, "2015-10-25")
    # our view will render a basic json object  
    #render json:activities
    user_id = data["uid"]
    @user = User.find_by(:uid => user_id)
    @sleeps = Sleep.where(:uid => user_id)
    @activities = Activity.where(:uid => user_id)
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
    
    # specifies date range to request data from
    # client.activities_on_date('today')

    record = Sleep.find_or_initialize_by(:uid => fitbit_user_id, :date => date)
    sleepinfo = client.sleep_on_date(date)
    unless sleepinfo["sleep"].nil?
      sleepinfo["sleep"].each do |s|
        if s["isMainSleep"] == true
          record.update_attributes(:awakeDuration => s["awakeDuration"], :awakeningsCount => s["awakeningsCount"], :totalMinutesAsleep => s["minutesAsleep"], :totalTimeInBed => s["timeInBed"])
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
    dates = []
    awakeDurations = []
    awakeningsCounts = []
    totalMinutesAsleeps = []
    totalMinutesInBeds = []
    sleeps.each do |s|
      dates.push(s[:date])
      awakeDurations.push(s[:awakeDuration])
      awakeningsCounts.push(s[:awakeningsCounts])
      totalMinutesAsleeps.push(s[:totalMinutesAsleep])
      totalMinutesInBeds.push(s[:totalMinutesInBed])
    end
    @chart = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(:text => "Sleep summary")
      f.xAxis(:categories => dates)
      f.series(:name => "total Minutes in Beds", :yAxis => 0, :data => totalMinutesInBeds)
      f.series(:name => "total minutes asleep", :yAxis => 1, :data => totalMinutesAsleeps)
      f.yAxis [
        {:title => {:text => "Total Minutes in Bed", :margin => 70} },
        {:title => {:text => "Total Minutes Asleep"}, :opposite => true},
      ]

      f.legend(:align => 'right', :verticalAlign => 'top', :y => 75, :x => -50, :layout => 'vertical',)
      f.chart({:defaultSeriesType=>"column"})
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
        {:title => {:text => "Total steps", :margin => 70} },
        {:title => {:text => "Total sedentary minutes"}, :opposite => true},
      ]

      f.legend(:align => 'right', :verticalAlign => 'top', :y => 75, :x => -50, :layout => 'vertical',)
      f.chart({:defaultSeriesType=>"column"})
    end
    return @chart    
  end
end