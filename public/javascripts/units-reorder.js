/* FILE: units-reorder.js */

$(document).ready(function(){
  $("#confirm-reorder").click(function() {
    $("#reorder-rows-form").trigger('submit');
  });

  $(".reorder-attributes.available").find('input, select').prop('disabled', true);
  $(".reorder-checkbox, .reorder-direction, .reorder-remove").hide();
  $(".reorder-attributes.available label").bind('click', function(event){
    event.preventDefault();
  });
  $(".reorder-attributes.available input:checkbox").bind('click', function(event){
    event.preventDefault();
  });
  $(".reorder-attributes.available").delegate(".reorder-add", 'click', function(event){
    var $command, $attribute, $clone, $direction, $add, $remove, $selected, uid, original_background_color;

    $command    = $(this);
    $attribute  = $command.parent(".reorder-attribute");
    $clone      = $attribute.clone();
    $direction  = $clone.find(".reorder-direction");
    $add        = $clone.find(".reorder-add");
    $remove     = $clone.find(".reorder-remove");
    $selected   = $(".reorder-attributes.selected:first");
    uid         = new Date().getTime();
    original_background_color = $attribute.css('backgroundColor');

    $clone.data('uid', uid)
          .find('input, select').prop('disabled', false).end()
          .find('label, .reorder-checkbox input:checkbox').bind('click', function(event){
            event.preventDefault();
          }).end()
          .find(".reorder-checkbox input:checkbox").prop('checked', true).end()
          .hide()
          .appendTo($selected);

    $direction.show();
    $add.hide();
    $remove.show();

    $clone.prepend('<i class="handle icon-resize-vertical"></i>')
          .show()
          .css({ backgroundColor : '#FCEFA1' })
          .animate({ backgroundColor : original_background_color }, 400);

    $attribute.addClass('uid-'+uid).hide();

    $("#confirm-reorder").prop("disabled", false).removeClass("disabled");

    event.preventDefault();
    event.stopImmediatePropagation();
  });

  $(".reorder-attributes.selected").delegate(".reorder-remove", 'click', function(event){
    var $remove, $clone, uid, $available, $attribute;

    $remove     = $(this);
    $clone      = $remove.parent(".reorder-attribute");
    uid         = $clone.data('uid');
    $available  = $(".reorder-attributes.available:first");
    $attribute  = $available.find(".uid-"+uid);

    $clone.remove();
    $attribute.removeClass("uid-"+uid).fadeIn(300);

    if ($(".reorder-attributes.selected .reorder-attribute").length === 0) {
      $("#confirm-reorder").prop("disabled", true).addClass("disabled");
    }

    event.preventDefault();
    event.stopImmediatePropagation();
  });

  $(".reorder-attributes.selected").sortable({
    axis                  : 'y',
    handle                : 'i.handle',
    cursor                : 'move',
    placeholder           : 'ui-state-highlight',
    forcePlaceholderSize  : true,
    opacity               : 0.5
  });
});
