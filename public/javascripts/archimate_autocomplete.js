(function( $ ){

  // PLUGIN
  $.fn.archimate_autocomplete_setup = function() {

    return this.each(function(){
      var $field      = $(this),
      controller  = $field.data('autocompletion-controller'),
      action      = $field.data('autocompletion-action') || 'list',
      cache       = {},
      path,
      lastXhr;

      if (action === 'index') {
        path = "/"+ controller +".json";
      } else {
        path = "/"+ controller +"/"+action+".json";
      }

      $field.autocomplete({
        minLength: 0,
        source: function( request, response ) {
          var term = request.term;
          if ( term in cache ) {
            response( cache[ term ] );
            return;
          }
          lastXhr = $.getJSON( path, request, function( data, status, xhr ) {
            cache[ term ] = data;
            if ( xhr === lastXhr ) {
              response( data );
            }
          });
        } // source: function( request, response ) {
      }).focus(function() {// $field.autocomplete({
        if (this.value == "") {
          $(this).autocomplete('search', '');
        }
      }); //focus;

    }); // return this.each(function(){

  };

})( jQuery );

