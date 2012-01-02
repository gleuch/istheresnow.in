helpers do

  def dev?; Sinatra::Application.environment.to_s == 'development'; end
  def stage?; Sinatra::Application.environment.to_s == 'staging'; end
  def test?; Sinatra::Application.environment.to_s == 'testing'; end
  def scrape?; Sinatra::Application.environment.to_s == 'scraper'; end
  def prod?; Sinatra::Application.environment.to_s == 'production'; end

  def flashes?;
    !FLASH_TYPES.reject{|v| flash[v].blank?}.blank?
  end

  def show_flashes
    FLASH_TYPES.reject{|v| flash[v].blank?}.map{|v| "<div class=\"flash flash_#{v.to_s}\">#{flash[v]}</div>"}.join('')
  end

  def pluralize(num=0, str='', p_str=nil)
    if num == 1
      str
    else
      p_str || str.pluralize
    end
  end


  def find_place_and_fetch_weather(q=nil)
    q ||= params[:q] # sniff it
    
    if q.match(GEO_REGEXP)
      q = q.strip rescue nil
    else
      q = q.strip.underscore.humanize.downcase rescue nil
    end
    return if q.blank? || ['index'].include?(q) || q.length < 2


    # --- PLACE ---------------------
    begin
      # Format up geo lat/lng
      q = q.split(',').map{|g| format_geo_coord(g) }.join(',') if q.match(GEO_REGEXP)

      @place = lookup_place_by_search(q)
      @place ||= lookup_place_by_place(q)
      @place ||= lookup_place_via_service(q) unless @skip_geoloc_service

      puts "@place: #{@place.inspect}"

      # Add to place search terms
      PlaceSearch.create(:place_id => @place.id, :query => q, :active => true) unless @place.blank?
    rescue => err
      Audit.error(:loggable => Place, :message => "Unable to find place (#{q}): #{err}", :script => __FILE__)
    end


    # --- WEATHER -------------------
    begin
      lookup_weather_for_place(@place) if !@place.blank? && (@place.weather.blank? || !@place.weather.recent?)
    rescue => err
      Audit.error(:loggable => Weather, :message => "Unable to find weather for place (#{q}): #{err}", :script => __FILE__)
    end
  end

  def lookup_place_by_search(q)
    place = PlaceSearch.where("LOWER(query)=?", q).first
    @skip_service = true unless place.blank? # Don't let us keep looking up a bad item
    place.place rescue nil
  end

  def lookup_place_by_place(q)
    # Lookup via geo latitude and longitude
    if q.match(GEO_REGEXP)
      puts "Searching Place (Geo): #{q}"
      lat = q.gsub(GEO_REGEXP, '$1'), lng = q.gsub(GEO_REGEXP, '$3')
      place = Place.available.near(lat, lng)

    # Lookup via postal code
    elsif q.match(/^\d+$/)
      puts "Searching Place (Postal Code): #{q}"
      place = Place.available.where("LOWER(postal_code)=?", q)
    
    # Lookup more complex term
    else
      puts "Searching Place (All): #{q.underscore.humanize}"
      geo = q.split(',')
      location, region = geo.pop, geo.pop

      place = Place.available.where("LOWER(postal_code)=? OR LOWER(city)=? OR LOWER(nickname)=?", location, location, location)
      place = place.where("LOWER(suburb)=? OR LOWER(state)=? OR LOWER(country_code)=?", region, region, region) unless region.blank?
    end

    place.first rescue nil
  end
  
  def lookup_place_via_service(q)
    puts "Fetching Place: #{q}"

    # lookup_place_via_google(q)
    lookup_place_via_yahoo(q)
  end

  def lookup_weather_for_place(p=nil)
    p ||= @place
    return nil if p.blank?

    lookup_weather_via_yahoo(p)
  end



  def format_geo_coord(g); sprintf("%.4f", g.to_f).to_f; end

end


%w(actions display google.maps yahoo.maps yahoo.weather).each{|r| require "#{APP_ROOT}/lib/helpers/#{r}"}