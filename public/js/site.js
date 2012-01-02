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

  if (history.pushState) {
    $(window).bind('popstate', istheresnowin.popstate);
    history.ready = true;
  }

});

var istheresnowin = {
  query : null,
  _place : null,
  
  default_place : function(r) {
    istheresnowin._place = r;
    if (history.pushState && !history.initState) {
      history.initState = true;
      history.replaceState(r, window.title, location.href);
    }
  },
  
  popstate : function(e) {
    if (!history.ready || !e.originalEvent.state) return;
    if (e.originalEvent.state.place) istheresnowin.title(e.originalEvent.state.place);
    istheresnowin.html(e.originalEvent.state);
  },

  search : function(q) {
    if (this.query == q) {
      istheresnowin.search_complete();
      return;
    }

    this.query = q;

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
    $('#answer').hide();
  },

  search_complete : function() {
    $('#loading, #search').hide();
    $('#answer').show();
  },

  search_success : function(r,s,p) {
    if (s == 'success') {
      istheresnowin.html(r);
    } else {
      istheresnowin.search_error(r,s,p);
    }
  },
  
  search_error : function(r,s,p) {
    istheresnowin.html()
  },

  html : function(r) {
    if (r && r.place != '') {
      $('#place_name').html( r.place );
      if (r.weather) {
        // show weather here
      } else {
        $('#place_answer').html( i18n.defaults.dunno );
      }

      istheresnowin.title(r.place);
      if (r.url && history.pushState) history.pushState(r, window.title, r.url);
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
  
}