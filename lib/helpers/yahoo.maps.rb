helpers do

  def lookup_place_via_yahoo(q)
    places, gflags = [], 'A'

    # Fetch from Google
    uri = "http://where.yahooapis.com/geocode?q=#{CGI::escape(q)}"
    gflags << 'R' if q.match(/^([\-\+\d\.\'\"\s]+)(\,)([\-\+\d\.\'\"\s]+)$/)
    uri << "&gflags=#{gflags}"
    uri << "&appid=#{configatron.yapps_id}"

    puts "Yahoo!: #{uri}"
    info = Net::HTTP.get URI.parse(uri) rescue nil
    return nil if info.blank?

    # Parse XML
    json = Crack::XML.parse(info) rescue nil

    # Parse location information
    if json['ResultSet']['Found'].to_i > 0
      json['ResultSet']['Result'] = [ json['ResultSet']['Result'] ] if json['ResultSet']['Result'].is_a?(Hash)


      json['ResultSet']['Result'].each do |result|
        opts = {:service_name => 'Yahoo', :available => true, :active => true}

        r = {
          :woeid => :woeid,
          :latitude => :geo_latitude,
          :longitude => :geo_longitude,
          :city => :city,
          :state => :state,
          :countrycode => :country_code,
          :name => :full_name,
          :line2 => :full_name,
          :uzip => :postal_code,
          :postal => :postal_code,
          :county => :region
        }
        
        r.each do |k,v|
          opts[v] ||= result[k.to_s] rescue nil
        end

        [:geo_latitude, :geo_longitude].each{|v| opts[v] = format_geo_coord(opts[v])}

        begin
          p = Place.where(:geo_latitude => opts[:geo_latitude], :geo_longitude => opts[:geo_longitude]).first
          unless p.blank?
            places << p if p.update_attributes(opts)
          else
            p ||= Place.new(opts)
            places << p if p.save
          end
        rescue => err
          puts "omgwtf?: #{err}"
          nil
        end
      end
    end

    places.shift rescue nil
  end

end