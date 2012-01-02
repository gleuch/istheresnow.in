
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

    begin
      # Format up geo lat/lng
      q = q.split(',').map{|g| format_geo_coord(g) }.join(',') if q.match(GEO_REGEXP)

      @place = lookup_place_by_search(q)
      @place ||= lookup_place_by_place(q)
      @place ||= lookup_place_via_service(q) unless @skip_geoloc_service

      puts "@place: #{@place.inspect}"

      # Add to place search terms
      PlaceSearch.create(:place_id => (!@place.blank? ? @place.id : nil), :query => q, :active => true) rescue nil
    rescue => err
      Audit.error(:loggable => Place, :message => "Unable to find place (#{q}): #{err}", :script => __FILE__)
    end
      
    begin
      lookup_weather_for_place(@place) if !@place.blank? && !@place.weather.blank? && !@place.weather.recent?
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
    places = []

    puts "Fetching Place: #{q}"

    # Fetch from Google
    uri = "http://maps.googleapis.com/maps/api/geocode/json?sensor=#{!params[:sensor].blank? ? 'true' : 'false'}"

    if q.match(/^([\-\+\d\.\'\"\s]+)(\,)([\-\+\d\.\'\"\s]+)$/)
      uri << "&latlng=#{CGI::escape(q)}"
    else
      uri << "&address=#{CGI::escape(q)}"
    end

    info = Net::HTTP.get URI.parse(uri) rescue nil
    return nil if info.blank?

    # Parse JSON
    json = JSON.parse(info) rescue nil

    # Parse location information
    if json['status'] == 'OK' && !json['results'].blank?
      json['results'].each do |result|
        puts result['formatted_address']

        opts = {:service_name => 'Google', :available => true, :active => true}

        # Match up types accordingly...
        result['address_components'].each do |addr|
          opts[:city]           = addr['long_name'] if addr['types'].include?('locality')
          opts[:suburb]         = addr['long_name'] if addr['types'].include?('sublocality')
          opts[:state]          = addr['short_name'] if addr['types'].include?('administrative_area_level_1')
          opts[:region]         = addr['short_name'] if addr['types'].include?('administrative_area_level_2')
          opts[:postal_code]    = addr['short_name'] if addr['types'].include?('postal_code')
          opts[:country_code]   = addr['short_name'] if addr['types'].include?('country')
        end

        opts[:city] ||= result['formatted_address']
        opts[:full_name] = result['formatted_address']

        unless result['geometry']['location'].blank?
          opts[:geo_latitude] = format_geo_coord(result['geometry']['location']['lat'])
          opts[:geo_longitude] = format_geo_coord(result['geometry']['location']['lng'])
        end

        begin
          p = Place.new(opts)
          places << p if p.save
        rescue => err
          nil
        end
      end
    end

    places.shift rescue nil
  end

  def lookup_weather_for_place(p=nil)
    p ||= @place
    return nil if p.blank?

    # FETCH WEATHER HERE
  end



  # --- Templates ---------------------

  def set_current_user_locale
    locale = session[:locale]
    locale ||= params[:locale] unless params[:locale].blank?
    locale ||= 'en'
    session[:locale] = locale if APP_LOCALES.keys.include?(locale.to_sym)
  end


  def set_template_defaults
    @meta = {
      :description => t.template.meta.description,
      :robots => "noindex,nofollow"
    }
    
    @title = nil
    @body_class = []
  end

  def page_title
    str = [t.title_name]
    str.unshift(@title) unless @title.blank?
    str.join(' | ')
  end

  def locale_haml(f,locale=nil)
    locale ||= session[:locale]
    begin
      haml("#{f.to_s}.#{locale}".to_sym)
    rescue
      Audit.warning(:loggable => Sinatra, :message => "Locale HAML: Missing language file: #{f}", :script => f)
      (dev ? "<p><em>Error:</em> Missing language file for #{f}.</p>" : '')
    end
  end



  def error_messages_for(object, header_message=nil, clear_column_name=false)
    u_klass, str = object.class.name.underscore.pluralize.to_sym, ''
    
    # Use model name, if translated, else just humanize it.
    h_klass = t.models[object.class.name.underscore.to_sym].downcase if t.models[object.class.name.underscore.to_sym].translated?
    h_klass ||= object.class.name.underscore.humanize.downcase


    if !object.errors.blank?
      str << "<div class='form_errors'>"

      if !header_message.blank?
        str << "<div class='form_errors_header'>#{header_message}</div>"
      else
        m = (!object.new_record? ? 'update' : 'create').to_sym
        s = t.errors[u_klass].heading[m] if t.errors[u_klass].heading[m].translated? rescue nil
        s ||= t.defaults.error_for.send(m, h_klass)
        str << "<div class='form_errors_header form_errors_for_#{m.to_s}'>#{s}</div>"
      end

      str << "<ul>"
      object.errors.keys.each do |err|
        err = err[1] if clear_column_name == true
        str << "<li>#{t.errors[u_klass][err.to_sym]}</li>"
      end

      str << "</ul>"
      str << "</div>"
    end

    str
  end


  def render_place
    find_place_and_fetch_weather

    @canonical_url = "/#{@place.search.query}" rescue nil
    @canonical_url ||= "/#{@place.geo_latitude},#{@place.geo_longitude}" rescue nil

    respond_to do |format|
      format.html {
        @title = @place.name rescue t.places.unknown
        haml :'places/show'
      }
      format.json { place_json }
      format.xml { place_xml }
      format.rss { place_rss }
    end
  end


  def place_json(p=nil)
    p ||= @place

    unless @place.blank?
      obj = {:place => @place.name, :url => @canonical_url, :geo => {:latitude => @place.geo_latitude, :longitude => @place.geo_longitude}}
      unless @place.weather.blank?
        status = {:snow => @place.weather.snow?, :sleet => @place.weather.sleet?, :rain => @place.weather.rain?}
        obj[:weather] = {:name => t.weathers.noun[@place.weather.name.to_sym], :event => t.weathers.verb[@place.weather.name.to_sym], :status => status}
      else
        obj[:error] = true
        obj[:message] = t.weathers.unknown
      end
    else
      obj = {:place => false, :error => true, :message => t.places.unknown}
    end

    obj.to_json(:callback => params[:callback])
  end

  def place_xml
  end

  def place_rss
  end

  def format_geo_coord(g); sprintf("%.4f", g.to_f).to_f; end


  class Array
    def humanize_join(str=',')
      if self.length > 2
        l = self.pop
        "#{self.join(', ')} #{str} #{l}"
      elsif self.length == 2
        "#{self.shift} #{str} #{self.pop}"
      else
        self.to_s rescue ''
      end
    end

    def and_join
      self.humanize_join( R18n.t.defaults.and )
    end

    def or_join
      self.humanize_join( R18n.t.defaults.or )
    end
  end
end