jQuery(document).ready(function() {

  /* Allow POST/DELETE/PUT method POST requests from links. */
  $('a[data-submit]').each(function() {
    $(this).attr('href', $(this).data('submit')).click(function() {
      var link = $(this),
          href = link.data('submit'),
          method = link.data('method'),
          target = link.attr('target'),
          form = $('<form method="post" action="' + href + '"></form>'),
          metadata_input = '<input name="_method" value="' + method + '" type="hidden" />';

      if (target) form.attr('target', target);
      form.hide().append(metadata_input).appendTo('body');
      form.submit();
      return false;
    });
  })

  if (navigator.geolocation) {
    $('#options_current_loc a').click(function() {
      isthereweatherin.locate();
      return false;
    });
  } else {
    $('#options_current_loc').hide();
  }
  
  $('#options_search a').click(isthereweatherin.search_toggle);
  $('#options_map a').click(isthereweatherin.map_toggle);
  $('#search form').submit(isthereweatherin.search_form);

  if (history.pushState) {
    $(window).bind('popstate', isthereweatherin.popstate);
    history.ready = true;
  }

});


var isthereweatherin = {
  query : null,
  _place : null,
  _current_place : null,
  _map : null,
  
  default_place : function(r) {
    isthereweatherin._place = r;
    if (history.pushState && !history.initState) {
      history.initState = true;
      history.replaceState(r, window.title, location.href);
      isthereweatherin.pageview();
      $(document).ready(function() {
        if (localStorage && localStorage.show_map) isthereweatherin.map_toggle();
      });
    }
  },
  
  popstate : function(e) {
    if (!history.ready) return;

    var s = e.originalEvent.state;
    if (!s) s = isthereweatherin._current_place;
    if (!s) s = isthereweatherin._place;

    isthereweatherin._current_place = s;
    isthereweatherin.html(s);
    isthereweatherin.map_move();
    
    isthereweatherin.pageview();
  },
  
  pageview : function() {
    if (_gaq_last_pageview != location.href) {
      _gaq.push(['_trackPageview', location.href.replace(location.origin, '')]);
      _gaq_last_pageview = location.href;
    }
  },

  map_init : function(lat, lng) {
    var geo = isthereweatherin.map_coords(lat, lng),
        opts = {
          zoom: 10,
          disableDefaultUI: true,
          styles : [{stylers: [{ saturation: -100 }]}],
          center: new google.maps.LatLng(geo.latitude, geo.longitude),
          mapTypeId: google.maps.MapTypeId.ROADMAP
        };

    isthereweatherin._map = new google.maps.Map(document.getElementById('map_area'), opts);
  },

  map_coords : function(lat, lng) {
    if (isthereweatherin._current_place && isthereweatherin._current_place.geo) {
      if (!lat) lat = isthereweatherin._current_place.geo.latitude;
      if (!lng) lng = isthereweatherin._current_place.geo.longitude;
    } else if (isthereweatherin._place && isthereweatherin._place.geo) {
      if (!lat) lat = isthereweatherin._place.geo.latitude;
      if (!lng) lng = isthereweatherin._place.geo.longitude;
    } else {
      if (!lat) lat = 40.7143;
      if (!lng) lng = -74.006;
    }

    return {latitude:lat, longitude:lng};
  },

  map_toggle : function() {
    if ($('#map').is(':hidden') || !$('#map').is(':visible')) {
      $('#map').show();
      if (localStorage) localStorage.show_map = true;
      if (!isthereweatherin._map) isthereweatherin.map_init();
      google.maps.event.trigger(isthereweatherin._map, 'resize');
      isthereweatherin.map_move();
    } else {  
      $('#map').hide();
      if (localStorage) localStorage.removeItem('show_map');
    }
  },
  
  map_move : function(lat, lng) {
    var geo = isthereweatherin.map_coords(lat, lng);
    if (isthereweatherin._map) {
      isthereweatherin._map.setCenter(new google.maps.LatLng(geo.latitude, geo.longitude));
    } else {
      isthereweatherin.map_init(geo.latitude, geo.longitude);
    }
  },

  search_toggle : function() {
    if ($('#search').is(':hidden') || !$('#search').is(':visible')) {
      $('#answer, #loading').hide();
      $('#search').show();
    } else {
      $('#search').hide();
      $('#answer').show();
    }
  },

  search_form : function(e) {
    var q = $('#search_field').blur().val();
    if (!q || q == '' || q.length < 2) return false;
    isthereweatherin.search(q)
    return false;
  },

  search : function(q) {
    if (!!isthereweatherin._searching) return;

    if (this.query == q) {
      isthereweatherin.search_complete();
      return;
    }

    this.query = q;
    isthereweatherin._searching = true;

    $.ajax('/index.json', {
      data : {q : q},
      beforeSend : isthereweatherin.search_before_send,
      success : isthereweatherin.search_success,
      error: isthereweatherin.search_error,
      complete : isthereweatherin.search_complete
    })
  },

  search_before_send : function() {
    $('#loading').show();
    $('#answer, #search').hide();
  },

  search_complete : function() {
    isthereweatherin._searching = false;
    $('#loading, #search').hide();
    $('#answer').show();
  },

  search_success : function(r,s,p) {
    if (s == 'success') {
      isthereweatherin._current_place = r;
      isthereweatherin.map_move();
      isthereweatherin.html(r);

      if (r && r.place && r.url && history.pushState) {
        history.pushState(r, window.title, r.url);
        isthereweatherin.pageview();
      }
    } else {
      isthereweatherin.search_error(r,s,p);
    }
  },
  
  search_error : function(r,s,p) {
    isthereweatherin._current_place = null;
    isthereweatherin.html()
  },

  html : function(r) {
    if (r && r.place != '') {
      $('#place_name').html( r.place );
      
      console.log(r)
      
      if (r.weather && r.weather.status) {

        if (isthereweatherin.weather_site == 'hurricane') {
          if (r.weather.status.hurricane) {
            $('#place_answer').html( i18n.defaults.yes );
          } else if (r.weather.status.tropical_storm) {
            $('#place_answer').html( i18n.defaults.no_ts );
          } else {
            $('#place_answer').html( i18n.defaults.no );
          }

        } else {
          if (r.weather.status.snow) {
            $('#place_answer').html( i18n.defaults.yes );
          } else if (r.weather.status.sleet) {
            $('#place_answer').html( i18n.defaults.maybe );
          } else {
            $('#place_answer').html( i18n.defaults.no );
          }
        }
      } else {
        $('#place_answer').html( i18n.defaults.dunno );
      }

      isthereweatherin.title(r.place);
    } else {
      $('#place_name').html( i18n.places.unknown );
      $('#place_answer').html( i18n.defaults.dunno );
      isthereweatherin.title( i18n.places.unknown );
    }
  },

  title : function(p) {
    var t = [];

    if (p && p != '') t.push(p);
    t.push(i18n.title_name);
    t = t.join(' | ');

    window.title = t;
    $('title').text(t);
    return t;
  },

  locate : function() {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(isthereweatherin.locate_success, isthereweatherin.locate_error);
  },

  locate_success : function(pos) {
    var q = pos.coords.latitude +','+ pos.coords.longitude;
    isthereweatherin.search(q)
  },
  
  locate_error : function(msg) {
    $('#loading').hide();
    $('#answer').show();
  }
  
};