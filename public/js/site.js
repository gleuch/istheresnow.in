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
  
  
});