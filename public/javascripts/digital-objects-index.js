$(document).ready(function() {

  uncheckAll();

  if (!checkBoxes()) {
    $("#toggle-all").prop('disabled', true).addClass('disabled');
  }

  $("#sortable").sortable({
    cursor: 'move',
    placeholder : 'sortable-placeholder',
    forcePlaceholderSize : true,
    opacity : 0.7,
    update : function () {
      var order = $('#sortable').sortable('serialize');
      var action = "/digital_objects/sort";
      $.get(action+"?"+order, function(data) {});
    }
  });

  $(document).on('change', "[id^=digital_object_ids_]", function() {
    if($(this).is(':checked') ) {
      if(allChecked()) {
        $('#toggle-all').prop('checked', true);
      }
    } else {
      if($('#toggle-all').is(':checked')) {
        $('#toggle-all').prop('checked', false);
      }
    }
    toggleBulkDestroy();
  });

  $(document).on("click", "#bulk-destroy", function (){
    if ($(this).prop('disabled') === false) {
      var params = decodeURIComponent($('input:checkbox:checked').serialize());
      var action = "/digital_objects/bulk_destroy";
      $.get(action+"?"+params, function(data) {
        window.location.reload();
      });
    }
  });

  $(document).on('change', "#toggle-all", function() {
    var CheckBoxes = $("[id^=digital_object_ids_]");
    $(this).is(':checked') ? CheckBoxes.prop("checked", true) : CheckBoxes.prop("checked", false);
    toggleBulkDestroy();
  });

  function toggleBulkDestroy() {
    var checkBoxChecked = $('input:checkbox:checked');
    if (checkBoxChecked.length) {
      $("#bulk-destroy").prop('disabled', false).removeClass('disabled').addClass('btn-danger');
      $("#bulk-destroy i").addClass('icon-white');
    }
    else {
      $("#bulk-destroy").prop('disabled', true).addClass('disabled').removeClass('btn-danger');
      $("#bulk-destroy i").removeClass('icon-white');
    }
  }

  function uncheckAll() {
    $('input:checkbox:checked').prop('checked', false);
  }

  function checkBoxes() {
    var test = $("[id^=digital_object_ids_]").length ? true : false;
    return test;
  }

  function allChecked() {
    var test = true;
    $("[id^=digital_object_ids_]").each(function() {
      if(!$(this).is(':checked')) {
        test = false;
      }
    });
    return test;
  }

});

