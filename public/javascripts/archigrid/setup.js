/* FILE: setup.js */

$(document).ready(function(){

  $("#toggleToolbar").click(function(){
    $.archigrid.commons.jqgrid_table[0].toggleToolbar();
    $.archigrid.commons.jqgrid_table[0].clearToolbar();
  });

  $("#save-text-field-dialog").live("click", function(){
    $(this).prop("disabled", true).addClass("disabled");
    $.archigrid.editing.process_text_field_form();
  });

  $("#save-events-field-dialog").live("click", function(){
    $(this).prop("disabled", true).addClass("disabled");
    $.archigrid.editing.process_preferred_event_form();
  });
  
  $('#status-bar a').each(function(){
    $(this).attr('tabindex','-1');
  });  
  
  $('#view-options a').each(function(){
    $(this).attr('tabindex','-1');
  });    


  // Header: exclude link elements from tab navigation
  $('#header a').each(function(){
    //$(this).tabIndex = -1;
    $(this).attr('tabindex','-1');
  }); 

  $.archigrid.setup = {

    // Must be called before any configuration/setup action, see archigrid file
    // Notes for code maintainance:
    // 1 -  when the action units_controller#gridview receives a list of ordered
    //      attributes, via get params, post params, or flash session, it sends
    //      them to the view, and the array is saved in the attribute :'data-selected-attributes'
    //      of the jqGrid table element;
    //      the first time, though, no additional params are used, so the javascript
    //      will use its default list
    // 2 -  the function $.archigrid.setup.set_selected_attribute_names search for a list
    //      in that attribute, and if it doesn't find any, it uses a default list
    //      stored in $.archigrid.config.default_attribute_names
    // 3 -  the given or default list, is then saved in $.archigrid.config.selected_attribute_names
    //      to be available for the booting phase
    // 4 -  when the rest of configuration actions have been completed, the stored value
    //      is used in the activation of the grid, precisely in the postData option;
    //      the data in postData are sent by jqGrid when requesting the json data
    //      to populate the table; this data are sent to the action units_controller#grid
    // 5 -  inside the action, the method Unit.jqgrid_rows(@units, @selected_attributes) is called;
    //      it builds the query only with the requested attributes; the json-data
    //      is sent in response, and displayed by jqGrid
    // 6 -  when the user selects a list of attributes, these are sent to units_controller#gridview
    //      the process starts over from step 1, but this time the list is already set,
    //      and it will be sent back and forth, between the client and the server
    // 7 -  a special case is represented by add_rows and remove_rows actions, in units_controller:
    //      when the user submit the form, the list of attributes is sent as well;
    //      the actions in the controller do their job, then store the list in the flash session,
    //      so that it is available when the redirect to the gridview action: again, the process
    //      starts over from step 1
    set_selected_attribute_names : function(){
      // 1 - take the attributes set in the view, if present, or the default ones
      var selected_attribute_names =
      ( $.archigrid.commons.jqgrid_table.data('selected-attributes') ||
        $.archigrid.config.default_attribute_names );
      // 2 - ensure that id is always present and the first element
      selected_attribute_names = $.grep(selected_attribute_names, function(attribute_name, index){
        return attribute_name !== 'id';
      });
      var id = ['id'];
      selected_attribute_names = id.concat(selected_attribute_names);
      // 3 - now save the proper value in the config object (will be used during the grid lifecycle)
      $.archigrid.config.selected_attribute_names = selected_attribute_names;
      return this;
    },

    // Aggiunge il link "modifica" alle celle standalone-editable
    edit_text_command :function(){
      $.archigrid.commons.jqgrid_table.delegate("td.standalone-editable", "mouseenter", function(){
        var $edit_text_command_wrapper  = $("#standalone-edit-command-wrapper").clone().show();
        //var $edit_text_command          = $edit_text_command_wrapper.find("a");
        var $td                         = $(this);
        var $inner_wrapper              = $td.find(".inner-wrapper");
        // Only if the mouse hasn't hovered the cell yet
        if ($td.find(".inner-wrapper").length === 0) {
          $inner_wrapper =  $("<div />", {
            "class": "inner-wrapper",
            "css"  :  {
              "height"  : ($td.height()-3),
              "width"   : "100%",
              "position": "relative",
              "padding" :0
            }
          });
          $td.wrapInner($inner_wrapper);
        }

        $td.find(".inner-wrapper:first").append($edit_text_command_wrapper);
      })
      .delegate("td.standalone-editable", "mouseleave", function(){
        $(this).find("#standalone-edit-command-wrapper").remove();
      });
      return this;
    },

    select_columns_dialog : function(){
      $("#confirm-columns").click(function() {
        $.archigrid.editing.process_select_columns_form();
      });

      // Populate the form (this can be done immediately, because the content is static)
      var $list = $.archigrid.commons.select_columns_dialog.find("ul#columns-list");
      var $attr_template = $list.find("li");
      $attr_template.find("input:checkbox").attr('disabled',true);
      $.each($.archigrid.config.available_attributes(), function(index, attribute){
        // Create a new checkbox for the attribute
        var $new_attr_item = $attr_template.clone();
        $new_attr_item.show();

        // Set the checkbox
        var $checkbox = $new_attr_item.find("input:checkbox");
        var checked   = ($.inArray(attribute.attr_name, $.archigrid.config.selected_attribute_names) > -1);
        $checkbox.attr({
          value     : attribute.attr_name,
          disabled  : false,
          id        : $checkbox.attr('id') + attribute.attr_name,
          checked   : checked
        });

        // Sets its label
        var $label = $new_attr_item.find("label");
        // WARNING: crashes if attribute.label is undefined!
        $label.html(attribute.label);
        $label.attr({
          'for' : $checkbox.attr('id')
        })
        .css({
          cursor : 'pointer'
        });

        if (attribute.attr_name !== 'id') {
          $new_attr_item.appendTo($list);
        }
      });
      return this;
    },

    autoresize : function(){
      $(window).resize(function(){
        $.archigrid.commons.jqgrid_table.jqGrid('setGridHeight', $.archigrid.utils.available_height());
        $.archigrid.commons.jqgrid_table.jqGrid('setGridWidth', $.archigrid.utils.content_width());
      });
      return this;
    },

    go_to_row : function (target_row_number) {
      var scrolling_container_height, row_height, total_rows, pixels_to_row;

      scrolling_container_height = $.archigrid.utils.scrolling_container().height();
      row_height = $.archigrid.commons.jqgrid_table.find("tr[role='row']").eq(1).height();
      total_rows = $.archigrid.commons.jqgrid_table.data('total-entries');
      pixels_to_row = Math.round(scrolling_container_height / total_rows * target_row_number) - (row_height * 1.5);

      $.archigrid.utils.grid_viewport().animate({
        scrollTop : (pixels_to_row + 'px')
      }, 0);
    },

    auto_go_to_row : function () {
      var auto_go_to_row_conditions, target_row_number, self;

      self = this;
      auto_go_to_row_conditions = ( $.archigrid.commons.jqgrid_table.data('go-to-row-index') &&
        $.archigrid.commons.jqgrid_table.data('already_gone') === undefined );
      target_row_number         = $.archigrid.commons.jqgrid_table.data('go-to-row-index');

      if (!auto_go_to_row_conditions) {
        return false;
      }
      $.archigrid.commons.jqgrid_table.data('already_gone', true);
      self.go_to_row(target_row_number);
    },

    // Crea il checkbox nell'header della tabella jqgrid
    check_all_button : function () {
      var $check_all_wrapper, $check_button;
      $check_all_wrapper = $("table.ui-jqgrid-htable thead th:first");
      $check_button      = $("<input />").prop({
        type:'checkbox',
        id:'select-all-records',
        tabindex: '-1'
      });

      $check_all_wrapper.empty();
      if ($.archigrid.commons.jqgrid_table.data('total-entries') > 0) {
        $check_all_wrapper.append($check_button);
      }
      return this;
    }
  }; // $.archigrid.setup
});

