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
      istheresnowin.locate();
      return false;
    });
  } else {
    $('#options_current_loc').hide();
  }
  
  $('#options_search a').click(istheresnowin.search_toggle);
  $('#options_map a').click(istheresnowin.map_toggle);
  $('#search form').submit(istheresnowin.search_form);

  if (history.pushState) {
    $(window).bind('popstate', istheresnowin.popstate);
    history.ready = true;
  }

});


var istheresnowin = {
  query : null,
  _place : null,
  _current_place : null,
  _map : null,
  
  default_place : function(r) {
    istheresnowin._place = r;
    if (history.pushState && !history.initState) {
      history.initState = true;
      history.replaceState(r, window.title, location.href);
      istheresnowin.pageview();
      $(document).ready(function() {
        if (localStorage && localStorage.show_map) istheresnowin.map_toggle();
      });
    }
  },
  
  popstate : function(e) {
    if (!history.ready) return;

    var s = e.originalEvent.state;
    if (!s) s = istheresnowin._current_place;
    if (!s) s = istheresnowin._place;

    istheresnowin._current_place = s;
    istheresnowin.html(s);
    istheresnowin.map_move();
    
    istheresnowin.pageview();
  },
  
  pageview : function() {
    if (_gaq_last_pageview != location.href) {
      _gaq.push(['_trackPageview', location.href.replace(location.origin, '')]);
      _gaq_last_pageview = location.href;
    }
  },

  map_init : function(lat, lng) {
    var geo = istheresnowin.map_coords(lat, lng),
        opts = {
          zoom: 10,
          disableDefaultUI: true,
          styles : [{stylers: [{ saturation: -100 }]}],
          center: new google.maps.LatLng(geo.latitude, geo.longitude),
          mapTypeId: google.maps.MapTypeId.ROADMAP
        };

    istheresnowin._map = new google.maps.Map(document.getElementById('map_area'), opts);
  },

  map_coords : function(lat, lng) {
    if (istheresnowin._current_place && istheresnowin._current_place.geo) {
      if (!lat) lat = istheresnowin._current_place.geo.latitude;
      if (!lng) lng = istheresnowin._current_place.geo.longitude;
    } else if (istheresnowin._place && istheresnowin._place.geo) {
      if (!lat) lat = istheresnowin._place.geo.latitude;
      if (!lng) lng = istheresnowin._place.geo.longitude;
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
      if (!istheresnowin._map) istheresnowin.map_init();
      google.maps.event.trigger(istheresnowin._map, 'resize');
      istheresnowin.map_move();
    } else {  
      $('#map').hide();
      if (localStorage) localStorage.removeItem('show_map');
    }
  },
  
  map_move : function(lat, lng) {
    var geo = istheresnowin.map_coords(lat, lng);
    console.log('map move')
    if (istheresnowin._map) {
      istheresnowin._map.setCenter(new google.maps.LatLng(geo.latitude, geo.longitude));
    } else {
      istheresnowin.map_init(geo.latitude, geo.longitude);
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
    istheresnowin.search(q)
    return false;
  },

  search : function(q) {
    if (!!istheresnowin._searching) return;

    if (this.query == q) {
      istheresnowin.search_complete();
      return;
    }

    this.query = q;
    istheresnowin._searching = true;

    $.ajax('/index.json', {
      data : {q : q},
      beforeSend : istheresnowin.search_before_send,
      success : istheresnowin.search_success,
      error: istheresnowin.search_error,
      complete : istheresnowin.search_complete
    })
  },

  search_before_send : function() {
    $('#loading').show();
    $('#answer, #search').hide();
  },

  search_complete : function() {
    istheresnowin._searching = false;
    $('#loading, #search').hide();
    $('#answer').show();
  },

  search_success : function(r,s,p) {
    if (s == 'success') {
      istheresnowin._current_place = r;
      istheresnowin.map_move();
      istheresnowin.html(r);

      if (r && r.place && r.url && history.pushState) {
        history.pushState(r, window.title, r.url);
        istheresnowin.pageview();
      }
    } else {
      istheresnowin.search_error(r,s,p);
    }
  },
  
  search_error : function(r,s,p) {
    istheresnowin._current_place = null;
    istheresnowin.html()
  },

  html : function(r) {
    if (r && r.place != '') {
      $('#place_name').html( r.place );
      if (r.weather && r.weather.status) {
        if (r.weather.status.snow) {
          $('#place_answer').html( i18n.defaults.yes );
        } else if (r.weather.status.sleet) {
          $('#place_answer').html( i18n.defaults.maybe );
        } else {
          $('#place_answer').html( i18n.defaults.no );
        }
      } else {
        $('#place_answer').html( i18n.defaults.dunno );
      }

      istheresnowin.title(r.place);
    } else {
      $('#place_name').html( i18n.places.unknown );
      $('#place_answer').html( i18n.defaults.dunno );
      istheresnowin.title( i18n.places.unknown );
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
    navigator.geolocation.getCurrentPosition(istheresnowin.locate_success, istheresnowin.locate_error);
  },

  locate_success : function(pos) {
    var q = pos.coords.latitude +','+ pos.coords.longitude;
    istheresnowin.search(q)
  },
  
  locate_error : function(msg) {
    $('#loading').hide();
    $('#answer').show();
  }
  
};