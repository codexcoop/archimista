jQuery.fn.liveUpdate = function(list, options){

  var cache = {};
  var settings = $.extend( {
    'url' : '',
    'field' : '',
    'targetClass' : 'livesearch',
    'selectedClass' : 'highlight',
    'exclude' : {
      exclude: []
    }
  }, options);

  /* public methods */
  this.getTargetClass = function() {
    return settings.targetClass;
  };

  this.getSelectedClass = function() {
    return settings.selectedClass;
  };

  this.getUrl = function() {
    return settings.url;
  };

  this.reset = function() {
    cache = {};
    removeSelectedClass();
    this.val('');
    this.trigger('keyup');
  };

  /* end public methods */

  list = jQuery(list);

  this
  .keyup(filter).keyup()
  .parents('form').submit(function(){
    return false;
  });

  $('.'+settings.targetClass).live('click', function(){
    removeSelectedClass();
    $(this).addClass(settings.selectedClass);
  });

  return this;

  /* private methods */

  function filter(){
    var q = jQuery.trim(jQuery(this).val().toLowerCase());

    if (q in cache) {
      fill(cache[q]);
      return;
    }

    $.getJSON(settings.url+'?'+$.param(settings.exclude), {
      term: q
    }, function( data ) {
      cache[ q ] = data;
      fill(data);
    });
  }

  function fill(data) {
    var items = [];
    $.each(data, function(key, val) {
      items.push('<li><label class="radio '+settings.targetClass+'"><input name="'+settings.field+'" value="'+val.id+'" type="radio">'+val.value+'</label></li>');
    });
    if (items.length === 0) {
      list.html('<li>Nessun risultato trovato</li>');
    } else {
      list.html('');
      list.html(items.join(''));
    }
  }

  function removeSelectedClass () {
    $('.'+settings.targetClass).each(function() {
      if($(this).hasClass(settings.selectedClass)) {
        $(this).removeClass(settings.selectedClass);
      }
    });
  }
};