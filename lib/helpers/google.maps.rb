helpers do

  def lookup_place_via_google(q)
    places = []

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
        # puts result['formatted_address']

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

end