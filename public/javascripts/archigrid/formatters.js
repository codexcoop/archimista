/* FILE: formatters.js */

$(document).ready(function(){

// Reference: http://www.trirand.com/jqgridwiki/doku.php?id=wiki:custom_formatter
  $.archigrid.formatters = {

    level_string : function(cellvalue, options, rowObject){
      var unit     = $.archigrid.i18n.formatters.unit;
      var subunit  = '&mdash; ' + $.archigrid.i18n.formatters.subunit;

      if (cellvalue === 0) {
        return unit;
      } else if (cellvalue === 1) {
        return subunit;
      }
    },

    destroy_record : function(cellvalue, options, rowObject){
      var checkbox = '<input type="checkbox" class="record-ids selected-record-id" name="record_ids[]" value="'+ cellvalue +'" tabindex="-1" />';
      return checkbox;
    }
  };

});

