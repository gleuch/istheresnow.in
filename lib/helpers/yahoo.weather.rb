helpers do
  
  def lookup_weather_via_yahoo(p=nil)
    p ||= @place
    return if p.blank? || p.woeid.blank?

    codes = {0 => 'tornado', 1 => 'tropical storm', 2 => 'hurricane', 3 => 'severe thunderstorms', 4 => 'thunderstorms', 5 => 'mixed rain and snow', 6 => 'mixed rain and sleet', 7 => 'mixed snow and sleet', 8 => 'freezing drizzle', 9 => 'drizzle', 10 => 'freezing rain', 11 => 'showers', 12 => 'showers', 13 => 'snow flurries', 14 => 'light snow showers', 15 => 'blowing snow', 16 => 'snow', 17 => 'hail', 18 => 'sleet', 19 => 'dust', 20 => 'foggy', 21 => 'haze', 22 => 'smoky', 23 => 'blustery', 24 => 'windy', 25 => 'cold', 26 => 'cloudy', 27 => 'mostly cloudy (night)', 28 => 'mostly cloudy (day)', 29 => 'partly cloudy (night)', 30 => 'partly cloudy (day)', 31 => 'clear (night)', 32 => 'sunny', 33 => 'fair (night)', 34 => 'fair (day)', 35 => 'mixed rain and hail', 36 => 'hot', 37 => 'isolated thunderstorms', 38 => 'scattered thunderstorms', 39 => 'scattered thunderstorms', 40 => 'scattered showers', 41 => 'heavy snow', 42 => 'scattered snow showers', 43 => 'heavy snow', 44 => 'partly cloudy', 45 => 'thundershowers', 46 => 'snow showers', 47 => 'isolated thundershowers', 3200 => 'not available'}
    snow_codes, sleet_codes, rain_codes, wind_codes, storm_codes, sunny_codes = [7,13,14,15,16,41,42,46], [5,6,8,10,18], [1,2,3,4,5,6,8,9,10,11,12,17,18,35,37,38,39,40,45,47], [0,2,23,24,15], [0,1,2,3,4,15,37,38,39,41,45,47], [29,30,31,32,33,34]

    uri = "http://weather.yahooapis.com/forecastrss?w=#{p.woeid}"

    puts "Yahoo!: #{uri}"
    info = Net::HTTP.get URI.parse(uri) rescue nil
    return nil if info.blank?

    # Parse XML
    json = Crack::XML.parse(info)['rss']['channel'] rescue nil
    return nil if json.blank?

    # Parse location information
    ynow, today = json['item']['yweather:condition'], json['item']['yweather:forecast'][0]
    code = ynow['code'].to_i
    opts = {
      :service_name => 'Yahoo',
      :active => true,
      :place_id => p.id,
      :event_code => code,
      :event_name => codes[code],
      :temp_now => ynow['temp'],
      :temp_high => today['high'],
      :temp_low => today['low'],
      :precip_level => nil,
      :is_snow_event => snow_codes.include?(code),
      :is_sleet_event => sleet_codes.include?(code),
      :is_rain_event => rain_codes.include?(code),
      :is_wind_event => wind_codes.include?(code),
      :is_storm_event => storm_codes.include?(code),
      :is_sunny_event => sunny_codes.include?(code),
      :recorded_at => Time.parse(ynow['date'])
    }

    weather = Weather.where(:recorded_at => opts[:recorded_at], :place_id => opts[:place_id]).first rescue nil
    unless weather.blank?
      weather.update_attrbutes(opts)
      weather.update_attrbute(:updated_at, Time.now) # force this!
    else
      weather = Weather.create(opts)
    end

    p.weather = weather # do it!
  end
  
end