
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
    q ||= params[:id] # sniff it
    unless q.blank?
      begin
        puts "\n\n"
        @place = lookup_place_by_search(q)
        @place ||= lookup_place_by_place(q)
        @place ||= lookup_place_via_service(q)

        puts "@place: #{@place.inspect}"

        # Add to place search terms
        PlaceSearch.create(:place_id => @place.id, :query => q.downcase, :active => true) rescue nil unless @place.blank?
        lookup_weather_for_place(@place) if !@place.blank? && !@place.weather.recent?
      rescue => err
        puts "Error (#{q}): #{err}"
        nil
      end
    end
  end

  def lookup_place_by_search(q)
    PlaceSearch.where(:query => q).first.place rescue nil
  end

  def lookup_place_by_place(q)
    geo_rx = /^([\-\+\d\.\'\"\s]+)(\,)([\-\+\d\.\'\"\s]+)$/

    # Lookup via geo latitude and longitude
    if q.match(geo_rx)
      puts "Searching Place (Geo): #{q}"
      lat = q.gsub(geo_rx, '$1'), long = q.gsub(geo_rx, '$3')
      place = Place.available.near(lat, long)

    # Lookup via postal code
    elsif q.match(/^\d+$/)
      puts "Searching Place (Postal Code): #{q}"
      place = Place.available.where("LOWER(postal_code)=?", q.downcase)
    
    # Lookup more complex term
    else
      puts "Searching Place (All): #{q.underscore.humanize}"
      geo = q.underscore.humanize.split(',')
      location, region = geo.pop, geo.pop

      place = Place.available.where("LOWER(postal_code)=? OR LOWER(city)=? OR LOWER(nickname)=?", location.downcase, location.downcase, location.downcase)
      place = place.where("LOWER(suburb)=? OR LOWER(state)=? OR LOWER(country_code)=?", region.downcase, region.downcase, region.downcase) unless region.blank?
    end

    place.first rescue nil
  end
  
  def lookup_place_via_service(q)
    places = []

    puts "Fetching Place: #{q}"

    # Fetch from Google
    uri = 'http://maps.googleapis.com/maps/api/geocode/json?sensor=true'
    uri << "&address=#{CGI::escape(q)}"
    info = Net::HTTP.get URI.parse(uri) rescue nil
    return false if info.blank?

    # Parse JSON
    json = JSON.parse(info) rescue nil

    # Parse location information
    if json['status'] == 'OK' && !json['results'].blank?
      json['results'].each do |result|
        puts result['formatted_address']

        opts = {:service_name => 'Google', :available => true, :active => true}

        # Match up types accordingly...
        result['address_components'].each do |addr|
          opts[:city]           = addr['long_name'] if addr['types'].include?('sublocality')
          opts[:suburb]         = addr['long_name'] if addr['types'].include?('locality')
          opts[:state]          = addr['short_name'] if addr['types'].include?('administrative_area_level_1')
          opts[:region]         = addr['short_name'] if addr['types'].include?('administrative_area_level_2')
          opts[:postal_code]    = addr['short_name'] if addr['types'].include?('postal_code')
          opts[:country_code]   = addr['short_name'] if addr['types'].include?('country')
        end

        opts[:city] ||= result['formatted_address']
        opts[:full_name] = result['formatted_address']

        unless result['geometry']['location'].blank?
          opts[:geo_latitude] = result['geometry']['location']['lat']
          opts[:geo_longitude] = result['geometry']['location']['lng']
        end

        begin
          p = Place.new(opts)
          places << p if p.save
        rescue => err
          nil
        end
      end
    end

    places.pop rescue nil
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