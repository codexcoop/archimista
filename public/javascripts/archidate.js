/*!
  Version 0.0.3, 2011-08-02
*/

(function( $ ){

// PLUGIN
$.fn.archidate = function(options) {

  $.extend(true, $.fn.archidate.options, options||{});
  var o = $.fn.archidate.options;

  var $template = $(o.archidate_template).first();
  var $add_template_command = $(o.add_command);
  if ($template.length > 0 && $add_template_command.length > 0) {
    init_template.apply($template);
    setup_template_clone.apply($template);
  }

  // this is the wrapped set of archidate "events"
  return this.each(function(){
    // $(this) is the single archidate "event" in the page
    var $this = $(this);
    if ($this.not(o.archidate_template).length > 0) {
      init.apply($this);
    }
  });

};

// PRIVATE FUNCTIONS
function init(){
  // the html $elements are local to the single archidate "event" in the page
  // store the elements in the archidate data
  // TODO: [Luca] abbandonare questo approccio, rigestire tutto con delegate
  this.data("archidate-elements", make_elements_for_single_archidate.apply(this));

  remove_not_applicable_parts .apply(this);

  init_completed_status       .apply(this);
  init_editing_status         .apply(this);
  init_inactive_field_groups  .apply(this);
  init_inactive_fields        .apply(this);

  setup_format_togglers       .apply(this);

  setup_remove_command        .apply(this);
  setup_restore_command       .apply(this);
  setup_hide_command          .apply(this);
  setup_show_command          .apply(this);
  setup_preferred_command     .apply(this);

  setup_start_spec_post_option.apply(this);

  setup_equal_bounds          .apply(this);

  setup_year_fields           .apply(this);

  setup_notes                 .apply(this);

  setup_autocomplete_fields   .apply(this);

  setup_place_for_entity_type .apply(this);
}

function setup_place_for_entity_type(){
  var o = $.fn.archidate.options;
  var self = this;
  var $places = self.find(o.date_place);

  var $type = $(o.entity_type);

  $type.change(function(){
    if ($(this).val() == 'P') {
      $places.css({opacity:0.0}).addClass('active').removeClass('inactive');
      $places.not('.not-activable').find(o.field).removeAttr('disabled');
      $places.not('.not-activable').show().animate({opacity:1.0},'fast');
    } else {
      $places.animate({opacity:0.0},'fast', function(){
      $(this).addClass('inactive').removeClass('active').hide();
      $(this).find(o.field).attr({disabled:'disabled'});
    });
   }
  })
  .trigger('change');

  return this;
}

function setup_autocomplete_fields(){
  var o = $.fn.archidate.options;
  this.find(o.field + o.autocomplete).each(function(){
    var $this = $(this);
    $this.archimate_autocomplete_setup();
  });
  return this;
}

function remove_not_applicable_parts(){
  var o = $.fn.archidate.options;
  this.find(o.not_applicable).remove();
  return this;
}

function init_completed_status(){
  var o = $.fn.archidate.options;
  this.filter(o.completed).find([o.archidate_inner, o.hide_command, o.restore_command].join(",")).hide();
  return this;
}

function init_editing_status(){
  var o = $.fn.archidate.options;
  this.filter(o.editing).find([o.show_command, o.restore_command].join(",")).hide();
  return this;
}

function init_inactive_field_groups(){
  this.find($.fn.archidate.options.initially_inactive.join(",")).hide();
  return this;
}

function init_inactive_fields(){
  var o = $.fn.archidate.options;
//  selector_for_inactive_fields = ".archidate-format-wrapper.inactive  .archidate-field, .bound-wrapper.inactive .archidate-field"
  var selector_for_inactive_fields = $(o.initially_inactive).map(function(){
    return this+" "+o.field;
  }).get().join(", ");
  this.find(selector_for_inactive_fields).attr({disabled:"disabled"});
  return this;
}

// TODO: this function does to much
function setup_format_togglers(){
  var o = $.fn.archidate.options;
  var $archidate  = this;
  var $elements   = $archidate.data("archidate-elements");

  $elements.format_togglers.bind("change", function(event) {
    var $command  = $(this);
    var format    = $command.val(); // year or century
    var bound     = $command.data("bound");
    var $bound    = $elements.bounds[bound];

    if ($command.is(":checked")) {
      var $formats              = $bound.find(o.format_wrapper);

      var $parts_to_show = $(),
          $parts_to_hide = $();

      $parts_to_show      = $parts_to_show.add($formats.filter("."+format));
      $parts_to_hide      = $parts_to_hide.add($formats.not("."+format));

      var $active_independents  = $bound.find(o.format_independent+o.active);
      var $all_independents     = $bound.find(o.format_independent);

      $parts_to_hide.removeClass("active").addClass("inactive");

      if ($.inArray($command.val(), ['C','Y']) > -1) {
        $parts_to_show = $parts_to_show.add($active_independents);
        $all_independents.removeClass('not-activable');
      } else {
        $all_independents.addClass('not-activable');
        $parts_to_hide = $parts_to_hide.add($all_independents);
      }

      var $fields_to_enable     = $parts_to_show.find(o.field);
      var $fields_to_disable    = $parts_to_hide.find(o.field);

      $parts_to_hide.animate({opacity:0.0}, 'fast', function(){
        $(this).hide();
        $parts_to_show.removeClass("inactive")
                        .addClass("active")
                        .css({opacity:0.0})
                        .show()
                        .animate({opacity:1.0},'fast');
      });

      $fields_to_disable.attr({disabled:"disabled"});
      $fields_to_enable.removeAttr("disabled");
    }
  })
  .trigger("change");
  return this;
}

function setup_remove_command(){
  var $elements = this.data("archidate-elements");

  $elements.remove_command.bind("click", function(event){
    var $command = $(this);

    $command.hide();
    $elements.hide_command.hide();
    $elements.show_command.hide();
    $elements.restore_command.show();

    $elements.archidate_inner.slideUp('fast');

    $elements.destroy_field.val('1');
    return false;
  });
  return this;
}

function setup_restore_command(){
  var $elements = this.data("archidate-elements");

  $elements.restore_command.bind("click", function(event){
    var $command = $(this);

    $command.hide();
    $elements.hide_command.show();
    $elements.remove_command.show();

    $elements.archidate_inner.slideDown();

    $elements.destroy_field.val('0');
    return false;
  });
  return this;
}

function setup_show_command(){
  var $elements = this.data("archidate-elements");

  $elements.show_command.bind("click", function(event){
    var $command = $(this);

    $command.hide();
    $elements.archidate_inner.slideDown();
    $elements.hide_command.show();
    return false;
  });
  return this;
}

function setup_hide_command(){
  var $elements = this.data("archidate-elements");

  $elements.hide_command.bind("click", function(event){
    var $command = $(this);

    $command.hide();
    $elements.archidate_inner.slideUp('fast');
    $elements.show_command.show();
    return false;
  });
  return this;
}

function setup_start_spec_post_option(){
  var o = $.fn.archidate.options;
  var $elements = this.data("archidate-elements");
  var $start_spec_post_option = $elements.date_specs.start.find(o.post_option);
  $elements.date_specs.start.data("post_option", $start_spec_post_option);
  return this;
}

function setup_equal_bounds(){
  var o = $.fn.archidate.options;
  var $elements = this.data("archidate-elements");

  $elements.equal_bounds_command.bind("change", function(event) {
    var $command = $(this);

    if ( $command.is(":checked") ) {
      $elements.date_specs.start.find(o.post_option).remove();
      $elements.bounds.end.slideUp(100);
      $elements.bounds.end.find(o.field).attr({disabled:"disabled"});
    } else {
      var $end_active_fields = $elements.bounds.end.find(o.format_wrapper  + o.active +" "+ o.field);
      $end_active_fields.removeAttr("disabled");
      $elements.bounds.end.slideDown('fast');
      $elements.date_specs.start.append( $($elements.date_specs.start.data("post_option")) );
    }
  })
  .trigger("change");
  return this;
}

function setup_preferred_command(){
  var o = $.fn.archidate.options;
  var $current_preferred_command = this.find(o.preferred_command).first();

  $current_preferred_command.change(function(event){
    var $other_preferred_commands = $(o.preferred_command).not($current_preferred_command);
    if ( $current_preferred_command.is(":checked") ) {
      $other_preferred_commands.attr("checked", false);
    } else {
      $current_preferred_command.attr("checked", true);
    }
  });
}

function setup_year_fields(){
  var o = $.fn.archidate.options;
  var $year_fields = this.find(o.year_fields);

  $year_fields.blur(function(){
    var $year_field = $(this);
    if ($year_field.val().length === 0 || $year_field.val() == $year_field.data('placeholder')) {
      $year_field.val($year_field.data('placeholder')).css("color","#999");
    }
  });

  $year_fields.blur();

  var regexp = /[^0-9]+/; // string contain characters other than digits

  $year_fields.focus(function() {
    var $year_field = $(this);
    if($year_field.val().match(regexp) || $year_field.val() === 0) {
      $(this).val("").css("color","#000");
    }
  });

  // IE debug snippet, please don't remove
  //var $year_fields = $("input.archidate-field.year-text-field");
  //$year_fields.keypress(function(event){
  //  console.log(event.type + " => which: " + event.which + ", keyCode: " + event.keyCode + ", charCode: " + event.charCode)
  //});

  $year_fields.keyup(function(event){
    $(this).val( ($(this).val().match(/^[0-9]{1,4}/) || [""] )[0] );
  });

  return this;
} // setup_year_fields()

function setup_notes(){
  var o = $.fn.archidate.options;
  if (o.toggle_notes) {
    var $elements = this.data("archidate-elements");
    if ($elements.notes.val().length === 0) $elements.notes.hide();
    $elements.notes_command.bind('click',function(event) {
      $elements.notes.toggle();
      return false;
    });
  }
  return this;
}

function init_template(){
  var o = $.fn.archidate.options;

  this.data("add_command", $(o.add_command));
  this.hide();
  this.find("input, select, textarea").attr({disabled:'disabled'});
  this.find([o.show_command, o.restore_command].join(",")).hide();
  return this;
}

function setup_template_clone(){
  var o = $.fn.archidate.options;
  var $template = this;

  $template.data("add_command").click( function(event) {
    var new_index = new Date().getTime();
    var $clone    = $template.clone().removeAttr("id");

    // this goes first, because re-enables some elements that
    // could be disabled by the init
    $clone.find(o.template_active_fields.join(",")).removeAttr("disabled");

    // this goes after, because disables some elements that should be disabled
    // in an empty record (example: units with defaults equal bounds)
    init.apply($clone);

    // TODO: placeholder replacement deserves its own function
    $clone.find('input, select, textarea, label')
      .attr('id',   function(){ if ($(this).attr('id')) { return $(this).attr('id').replace(o.placeholder, new_index); } } )
      .attr('name', function(){ if ($(this).attr('name')) { return $(this).attr('name').replace(o.placeholder, new_index); } } )
      .attr('for',  function(){ if ($(this).attr('for')) { return $(this).attr('for').replace(o.placeholder, new_index); } } );

    $clone.prependTo($(o.template_target+":first"));
    $clone.slideDown();
    return false;
  });
  return this;
}

function make_elements_for_single_archidate(){
  var o = $.fn.archidate.options;
  return {
    format_togglers       : this.find(o.format_toggler),
    archidate_inner       : this.find(o.archidate_inner),
    destroy_field         : this.find(o.destroy_field),
    hide_command          : this.find(o.hide_command),
    show_command          : this.find(o.show_command),
    restore_command       : this.find(o.restore_command),
    remove_command        : this.find(o.remove_command),
    equal_bounds_command  : this.find(o.equal_bounds_command),
    notes                 : this.find(o.notes),
    notes_command         : this.find(o.notes_toggler),
    bounds                : {
      start : this.find(o.start_bound),
      end   : this.find(o.end_bound)
    },
    date_specs            : {
      start : this.find(o.start_date_spec),
      end   : this.find(o.end_date_spec)
    },
    fields                : {
      start : this.find(o.start_bound+" "+o.field),
      end   : this.find(o.end_bound+" "+o.field)
    }
  };
}

// DEFAULT OPTIONS
$.fn.archidate.options = {
  entity_type             : "#creator_creator_type",

  bound                   : ".bound-wrapper",
  data_bound_format       : "data-bound-format",
  format_toggler          : ".format-toggler",
  field                   : ".archidate-field",
  date_place              : ".archidate-place",
  autocomplete            : ".autocomplete",
  active                  : ".active",
  inactive                : ".inactive",
  format_wrapper          : ".archidate-format-wrapper",
  format_independent      : ".archidate-format-independent",
  equal_bounds_command    : ".equal-bounds-command",
  initially_inactive      : [ ".archidate-format-wrapper.inactive",
                              ".bound-wrapper.inactive"],
  not_applicable          : ".not-applicable",

  template_active_fields  : [ ".archidate-format-wrapper.active .archidate-field",
                              "#archidate-text-note",
                              ".destroy-archidate",
                              ".format-toggler",
                              ".equal-bounds-command",
                              ".archidate-notes",
                              ".archidate-field.preferred-event"],
  placeholder             : "new_archidate",
  template_target         : ".archidates-area",
  add_command             : "form .add-archidate",

  toggle_notes        : false,
  notes               : ".archidate-notes",
  notes_toggler       : ".date-notes-toggler",
  archidate_inner     : ".archidate-inner",
  editing             : ".editing",
  completed           : ".completed",
  archidate_template  : "#archidate-template",
  destroy_field       : "input:hidden.destroy-archidate",
  year_fields         : ".year-text-field",
  new_year_fields     : ".year-text-field[data-is-new='true']",

  start_bound     : ".bound-wrapper.start",
  end_bound       : ".bound-wrapper.end",
  start_date_spec : "[id$='_start_date_spec']",
  end_date_spec   : "[id$='_end_date_spec']",
  post_option     : "[value='post']",

  show_command      : ".show-archidate",
  hide_command      : ".hide-archidate",
  remove_command    : ".remove-archidate",
  restore_command   : ".restore-archidate",
  preferred_command : ".archidate-field.preferred-event"
};

})( jQuery );

