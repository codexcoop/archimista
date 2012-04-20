$(document).ready(function(){

  // functions namespacing
  $.relations = {

    remove_item : function(item){
      var self, $item, $container, $selected_list, trashed_id;
      self = this;

      if (item instanceof jQuery) { $item = item; } else { $item = $(item); }
      $container      = $item.parents(".relation-selection:first");
      $selected_list  = $item.parents(".selected-list:first");
      // restore the element in static suggested list, if present
      trashed_id = $item.find("input.related-id").val().toString();
      $container.find(".suggested-item[data-related-id="+ trashed_id +"]").show();
      // preserve the necessary fields ( _destroy and the id of the related object) for existing records
      // ( this makes sense only for records already saved in db, no need to pollute the dom )
      if ( !$item.hasClass('just-added') ) {
        $item.find("input.destroy-relation").val(true).appendTo($selected_list);
        $item.find("input:hidden").appendTo($selected_list);
      }
      // remove the item to avoid any possible confusion, will be easily recreated if needed
      $item.remove();
    }, // $.relations.remove_item()

    remove_all_items_from : function(selected_list){
      var self, $items, $container, $selected_list;
      self = this;

      if (selected_list instanceof jQuery) {
        $selected_list = selected_list;
      } else {
        $selected_list = $(selected_list);
      }
      $container  = $selected_list.parents(".relation-selection:first");
      $items      = $selected_list.find(".choice-item");
      // restore the elements in static suggested list, if present
      $container.find(".suggested-item").show();
      // preserve the _destroy field for existing records
      $selected_list.find(".item-action-trash").trigger('click');
    }, // $.relations.remove_all_items_from()

    add_element_to_selected : function(dom_element, id, label, label_short, label_full) {
      var self, $element, $container, selected_ids, is_already_present, new_index, $selected_list,
          $selected_item, $label, $label_short, $label_full, $inputs, $input, cardinality;
      self = this;

      if (dom_element instanceof jQuery) { $element = dom_element; } else { $element = $(dom_element); }

      $container          = $element.parents(".relation-selection:first");
      if ($container.data('cardinality') === 'unlimited'){
        cardinality       = $container.data('cardinality');
      } else {
        cardinality       = parseInt($container.data('cardinality'),10);
      }
      selected_ids        = $container
                            .find(".selected-list .choice-item input.related-id")
                            .filter(function(index){ return $(this).val() !== ""; })
                            .map(function(index, element){ return $(element).val().toString(); })
                            .get();
      is_already_present  = $.inArray(id.toString(), selected_ids) > -1;
      // 0 - kthxbye
      if (is_already_present) { return; }
      // do your job otherwise...
      new_index       = new Date().getTime();
      $selected_list  = $container.find(".selected-list:first");
      $selected_item  = $container.find(".choice-item.template:first").clone(); // template
      $selected_item.addClass('just-added').hide();
      $label          = $selected_item.find(".choice-item-label:first");
      $label_short    = $selected_item.find(".choice-item-label-short:first");
      $label_full     = $selected_item.find(".choice-item-label-full:first");
      $inputs         = $selected_item.find("input, select, textarea");
      // 1 - populate template with data from selection
      $inputs.each(function(index, element){
                $input = $(this);
                // assign a progressive random id (rails support)
                $input.attr("id", $input.attr("id").replace('_new_', new_index))
                      .attr("name", $input.attr("name").replace('_new_', new_index));
              })
              .filter(".related-id").val(id); // set the value of the related database record
      // 2 - set the visible text
      $label.html(label);
      $label_short.html(label_short);
      $label_full.html(label_full);
      // 3 - hide action elements
      $selected_item.find("span.ui-icon.item-actions").css({opacity:0.0});
      // 4 - setup element for insertion in dom
      //$selected_item.show().removeClass('template').show();
      $selected_item.removeClass('template');
      // 5 - remove all current items if only one allowed
      if (cardinality === 1) { $.relations.remove_all_items_from($selected_list); }
      // 6 - add to DOM, in the selected list
      $selected_list.append($selected_item);
      // 7 - show it
      $selected_item.show(); // notice: tr can't be animated in height
    } // $.relations.add_element_to_selected()

  }; // $.relations

  $(".relation-selection span.item-actions").css({opacity:0.0}); // actions not visible when page loads

  // show/hide commands on hover (delete, drag, add...)
  $(".selected-list, .suggested-list")
  .delegate(".choice-item", 'mouseenter', function(){
    $(this).find("span.item-actions").css({opacity:1.0});
  })
  .delegate(".choice-item", 'mouseleave', function(){
    $(this).find("span.item-actions").css({opacity:0.0});
  });

  // remove single items
  $(".selected-list").delegate(".item-action-trash", 'click', function(event){
    var $item, $container;
    $item = $(this).parents(".choice-item:first");
    $container = $item.parents(".relation-selection:first");
    $.relations.remove_item($item);
    $container.find(".add-suggested-invite").show();
    event.preventDefault();
  });

  // autocomplete 1: prevent unwanted submission of the form
  $(".relation-autocomplete").keydown(function(event){
    // disable "enter" in the autocomplete field
    if (event.which === 13) { event.preventDefault(); }
  });

  // autocomplete 2 - use the standard autocomplete of the application
  $(".relation-autocomplete").archimate_autocomplete_setup();

  // autocomplete 3 - customize the source to filter
  $(".relation-autocomplete").autocomplete('option', 'source', function(param, show_results){
    // Notes: param and add_callback are yielded by the native jQuery UI autocomplete() function.
    //  - param is the search term, and it is an object like: {term:'< user entered search >'}
    //  - show_results is a function; it must be called with an array of results,
    //    and it will take care to show them to the user

    var $widget, $element, results_array, url;
    $widget = this;
    $element = $widget.element;
    url = "/" + $element.data('autocompletion-controller') + "/" + $element.data('autocompletion-action');
    // phone home to get your data, and filter them before showing to the user
    $.getJSON(url, param, function(data, textStatus, jqXHR){
      // data is an array of objects [{id:1, value:'title A'}, {id:2, value:'title B'}]
      // create a new array of filtered results
      results_array = $.grep(data, function(result, index){
        // the conditions is: the id of the result record is not included in that of prohibited ids
        return ($.inArray(result.id, $element.data('excluded-ids')) === -1);
      });
      // add the the filtered results to the dom, as soon as the request completes
      show_results(results_array);
    });
  });

  // autocomplete 4 - setup callback upon select
  $(".relation-autocomplete").autocomplete('option', 'select', function(event, ui){
    $.relations.add_element_to_selected(this, ui.item.id, ui.item.value);
    // clear input after choice (warning, empirically, both this.val and return false are required to clear)
    $(this).val('');
    return false;
  });

  // hide suggested items whose id is excluded;
  // also, hide the invite if all suggested are excluded;
  $(".suggested-list, .results-list").each(function(index, list){
    var $list, $items, $invite_text, total_items=0, hidden_items=0;
    $list         = $(list);
    $items        = $list.find(".suggested-item");
    $invite_text  = $list.parents(".relation-selection:first").find(".add-suggested-invite");
    total_items   = $items.size();

    $items.each(function(index, item){
      var $item;
      $item = $(item);
      if ($.inArray($item.data('related-id'), $list.data('excluded-ids')) !== -1) {
        $item.hide();
        hidden_items += 1;
      }
    });

    if (total_items === hidden_items) { $invite_text.hide(); }
  });

  // add from static list when few records are available
  $(".suggested-list, .results-list").delegate('.item-action-add-suggested', 'click', function(event){
    var $this, $item, $container, $suggested_list;
    $this           = $(this); // the command element
    $item           = $this.parents(".choice-item:first");
    $container      = $item.parents(".relation-selection:first");
    $suggested_list = $item.parents(".suggested-list, .results-list");
    $.relations.add_element_to_selected(
      this,
      $this.data('selected-id'),
      $this.data('selected-value'),
      $this.data('selected-value-short'),
      $this.data('selected-value-full')
    );
    $item.addClass('hidden-suggested-item').hide();
    if ($suggested_list.find(".choice-item:visible").length === 0) {
      $container.find(".add-suggested-invite").hide();
    }
    event.preventDefault();
  });

});

