helpers do

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

    # flash.now[:info] = t.template.alert.high_traffic
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


# --- Places ------------------------

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

    unless p.blank?
      obj = {:place => p.name, :url => @canonical_url, :geo => {:latitude => p.geo_latitude, :longitude => p.geo_longitude}}
      unless p.weather.blank?
        status = {:snow => p.weather.snow?, :sleet => p.weather.sleet?, :rain => p.weather.rain?, :storm => p.weather.storm?}
        obj[:weather] = {:name => t.weathers.noun[p.weather.name.to_sym], :event => t.weathers.verb[p.weather.name.to_sym], :status => status}
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