/* FILE: formatters.js */

$(document).ready(function(){

// Reference: http://www.trirand.com/jqgridwiki/doku.php?id=wiki:custom_formatter
  $.archigrid.formatters = {

    // level_string : function(cellvalue, options, rowObject){
    //   var unit     = $.archigrid.i18n.formatters.unit;
    //   var subunit  = $.archigrid.i18n.formatters.subunit;
    //   var subsubunit  = $.archigrid.i18n.formatters.subsubunit;
    // 
    //   switch(cellvalue) {
    //     case 0:
    //       return unit;
    //     break;
    //     case 1:
    //       return subunit;
    //     break;
    //     case 2:
    //       return subsubunit;
    //     break;
    //     default:
    //       return unit;
    //   }
    // },

    // FIXME: rinominare in check_record
    destroy_record : function(cellvalue, options, rowObject){
      var checkbox = '<input type="checkbox" class="record-ids selected-record-id" name="record_ids[]" value="'+ cellvalue +'" tabindex="-1" />';
      return checkbox;
    }
  };

});

