/* FILE: keyboard_nav.js */

$(document).ready(function(){

  $.archigrid.keyboard_nav = {

    take_over_tab_navigation : function(rowid, iRow, iCol){
      var $cell, self;
      self = this;
      $cell = $.archigrid.utils.get_cell_by_id_and_index(rowid, iCol);

      $cell.find("input, select, textarea").unbind('keydown');
      $cell.find("input, select, textarea").bind('keydown', function(event){
        if ($.inArray(event.which, [9, 13, 27]) > -1) {
          $.archigrid.commons.jqgrid_table.data('just_navigated', true);
          event.stopImmediatePropagation();
          event.preventDefault();
          if (event.which === 13) {
            if($cell.hasClass("editable-jqgrid-native")) {
              $.archigrid.commons.jqgrid_table.jqGrid("saveCell",iRow,iCol);
            }
          } else if (event.which === 9) {
            event.type = 'keyup';
            self.go_to_next_logic_cell(event);
          } else if (event.which === 27) {
            $.archigrid.commons.jqgrid_table.jqGrid("restoreCell",iRow,iCol);
          }
          return false;
        } else {
          event.type = 'keyup';
          $(this).trigger(event);
        }
      });
    },

    next_cell_on_tab : function(){
      var $cell, override_nav_conditions, self;
      self = this;

      $(document).keyup(function(event){
        $cell = $.archigrid.utils.current_cell();
        // Store the currently selected cell to be reactivated when action has ended
        $.archigrid.commons.jqgrid_table.data('custom_selected_cell', $cell);
        // Determine navigation conditions
        override_nav_conditions = (event.keyCode === 9)  && // tab hit
        $cell.length > 0                        && // there is a current cell
        $.archigrid.utils.all_dialogs_close()   &&
        $.archigrid.utils.is_not_being_edited() &&
        !$.archigrid.commons.jqgrid_table.data('just_navigated');
        // Reset just_navigated flag
        $.archigrid.commons.jqgrid_table.data('just_navigated', false);

        if (override_nav_conditions) {
          self.go_to_next_logic_cell(event);
        } else {
          return;
        }
      });
      return this;
    },

    go_to_next_logic_cell : function(event){
      var $cell, row_down_conditions, row_up_conditions, self;
      self = this;
      $cell = $.archigrid.utils.current_cell();

      row_down_conditions = $cell.next().length === 0  &&   // current cell is last
      $.archigrid.utils.next_row().length > 0   && // there is a next row
      event.shiftKey === false;

      row_up_conditions   = $cell.hasClass('first-column') && // current cell is first
      $.archigrid.utils.preceding_row().length > 0  && // there is a preceding row
      event.shiftKey === true;

      if (row_down_conditions) {
        return self.go_to_beginning_of_next_row();
      } else if (row_up_conditions) {
        return self.go_to_end_of_previous_row();
      } else {
        return self.go_to_adiacent_cell(event);
      }
    },

    go_to_beginning_of_next_row : function(){
      var $target_cell;
      $target_cell = $.archigrid.utils.first_cell_in_next_row();
      if ($target_cell.length === 0) {
        return $target_cell;
      }

      $.archigrid.utils.grid_viewport().scrollLeft(0);

      $.archigrid.utils.grid_viewport().animate({
        scrollTop : '+=' + $.archigrid.utils.next_row().outerHeight(true) + 'px'
      },0);

      if($target_cell.hasClass("editable-jqgrid-native")) {
        $target_cell.trigger('click');
      } else {
        $target_cell.trigger('click').trigger('dblclick');
      }
      return $target_cell;
    },

    go_to_end_of_previous_row : function(){
      var $target_cell, visible_width, table_width, horizontal_scroll_size;

      visible_width = $.archigrid.utils.grid_viewport().outerWidth();
      table_width = $.archigrid.commons.jqgrid_table.width();
      horizontal_scroll_size = table_width - visible_width + 20;

      $.archigrid.utils.grid_viewport().animate({
        scrollLeft:"+="+horizontal_scroll_size+"px"
      },0);
      // Scroll up to maintain the current row at the same position in the viewport
      $.archigrid.utils.grid_viewport().animate({
        scrollTop : ('-=' + $.archigrid.utils.current_row().outerHeight(true) + 'px')
      },0);
      // Activate the the first cell in the new row
      $target_cell = $.archigrid.utils.last_cell_in_preceding_row();
      if($target_cell.hasClass("editable-jqgrid-native")) {
        $target_cell.trigger('click');
      } else {
        $target_cell.trigger('click').trigger('dblclick');
      }
      return $target_cell;
    },

    go_to_adiacent_cell : function(event){
      var $target_cell;
      event.type = 'keydown';
      if (event.shiftKey === false) {
        event.keyCode = 39;
        event.which   = 39;
      } else if (event.shiftKey === true) {
        event.keyCode = 37;
        event.which   = 37;
      }
      $("span#jqgrid_kn").trigger(event);

      $target_cell = $.archigrid.utils.current_cell();
      if($target_cell.hasClass("editable-jqgrid-native")) {
        $target_cell.trigger('click');
      } else {
        $target_cell.trigger('click').trigger('dblclick');
      }
      return $target_cell;
    },

    trigger_jqgrid_arrows : function(event){
      $(document).bind('keydown', function(event){
        $target_cell = $.archigrid.utils.current_cell();
        if($.inArray(event.which, [37,38,39,40]) > -1) {
          $("span#jqgrid_kn").trigger(event);
        }
        if(event.which == 32) {
          filter_active = $(document.activeElement).parents('tr').hasClass('ui-search-toolbar');
          is_modal_open = $.archigrid.utils.is_any_dialog_open();

          if(filter_active || is_modal_open) {
            $target_cell = undefined;
          } else {
            if($target_cell.hasClass("editable-jqgrid-native")) {
              $target_cell.trigger('click');
            } else {
              $.archigrid.events.dispatch_standalone_edit($target_cell);
              event.stopImmediatePropagation();
            }
          }
        }
        return $target_cell;
      });
    }
  };

});

