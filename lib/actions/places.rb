# Location by name
get "/:id" do
  pass if params[:id].blank?

  find_place_and_fetch_weather

  respond_to do |format|
    format.html {
      @title = @place.name rescue t.places.unknown
      @canonical_url = "/#{@place.name}" unless @place.blank?
      haml :'places/show'
    }
  end
end

get "/" do
  pass unless params.keys.length > 0

  params[:id] = params.keys.pop
  puts "??? #{params[:id]}"

  find_place_and_fetch_weather

  respond_to do |format|
    format.html {
      @title = @place.name rescue t.places.unknown
      @canonical_url = "/#{@place.name}" unless @place.blank?
      haml :'places/index'
    }
  end
end

get "/" do
  @place = Weather.recent.focus_city.is_snowing.random.first.place rescue nil

  respond_to do |format|
    format.html { haml :'places/index' }
  end
end