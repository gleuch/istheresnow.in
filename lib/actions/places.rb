# Location by params
get %r{/(index)?} do
  pass if params[:q].blank? && params.keys.length < 1
  params[:q] ||= params.keys.shift

  render_place
end

# Location by name
get "/:q" do
  pass if params[:q].blank?

  render_place
end

get "/" do
  obj = Weather.recent.focus_city

  case @weather_site_type
    when 'hurricane'
      obj = obj.is_hurricane
    else
      obj = obj.is_snowing
  end

  @place = obj.random.first.place rescue nil

  respond_to do |format|
    format.html { haml :'places/index' }
  end
end