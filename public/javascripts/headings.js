$(document).ready(function () {
  getHeadingList = function () {
    var id = $("#heading-list").attr('data-id');
    var controller = $("#heading-list").attr('data-controller');
    $.get('/headings/ajax_list', {
      related_entity_id: id,
      related_entity: controller
    }).success(function (data) {
      $("#heading-list").html(data);
    });
    return false;
  };

  getSelectedText = function (ids) {
    var text = '';
    var len = ids.length;
    for (var i = 0; i < len; i++) {
      var element = $('#' + ids[i]);
      if (element[0].tagName.toLowerCase() == "textarea" || element[0].tagName.toLowerCase() == "input") {
        var input = document.getElementById(element.attr('id'));
        var start = input.selectionStart;
        var end = input.selectionEnd;
        text = element.val().substring(start, end);
      } else {
        if (window.getSelection) {
          text = window.getSelection();
        } else if (document.getSelection) {
          text = document.getSelection();
        } else if (document.selection) {
          text = document.selection.createRange().text;
        }
      }
      if (text != '') break;
    }
    return text;
  };

  if ($("#heading-list").length) {
    getHeadingList();
  }


  $("#add-heading-modal").click(function (event) {
    event.preventDefault();
    var id = $(this).attr('data-id');
    var controller = $(this).attr('data-controller');
    $.get('/headings/modal_new', {
      related_id: id,
      related_controller: controller
    }).success(function (data) {
      $('#add-heading-container').html(data);
      $('#add-heading-container #add-heading-dialog').modal("show");
      if (controller == 'units') {
        text = getSelectedText(['unit_content']);
      } else {
        text = getSelectedText(['fond-abstract', 'fond-description', 'fond-history']);
      }
      $('#heading_name').val(text);
      if (text != '') {
        $("#create-heading-btn").removeClass('disabled').prop('disabled', false);
      }
    });
    return false;
  });

  $("#link-heading-modal").click(function (event) {
    event.preventDefault();
    var id = $(this).attr('data-id');
    var controller = $(this).attr('data-controller');
    $.get('/headings/modal_link', {
      related_entity_id: id,
      related_entity: controller
    }).success(function (data) {
      $('#link-heading-container').html(data);
      $('#link-heading-container #link-heading-dialog').modal("show");
    });
    return false;
  });

  $(document).delegate('#create-heading-btn', 'click', function (event) {
    $.post('/headings/modal_create', $('#new-heading-form').serialize(), function (data) {
      if (data.status === "success") {
        $('#add-heading-dialog').modal("hide");
        getHeadingList();
      } else {
        $("#heading_form_error").
        html('<div class="alert alert-error"><a class="close" data-dismiss="alert">×</a>' + data.msg + '.</div>');
      }
    }, 'json');
    event.stopImmediatePropagation();
  });

  $(document).delegate('#link-heading-btn', 'click', function (event) {
    $.post('/headings/ajax_link', $('#link-heading-form').serialize(), function (data) {
      if (data.status === "success") {
        $('#link-heading-dialog').modal("hide");
        getHeadingList();
      }
    }, 'json');
    event.stopImmediatePropagation();
  });

  $(document).delegate(".heading-remove", 'click', function (event) {
    event.preventDefault();
    var heading_id = $(this).attr('data-heading_id');
    var related_entity_id = $(this).attr('data-related_entity_id');
    var related_entity = $(this).attr('data-related_entity');
    $.post('/headings/ajax_remove', {
      related_entity_id: related_entity_id,
      related_entity: related_entity,
      heading_id: heading_id
    }).success(function (data) {
      if (data.status == 'success') {
        getHeadingList();
      } else {
        alert(data.msg)
      }
    }, 'json');
    event.stopImmediatePropagation();
  });

  $(document).delegate(":input[@name='heading_id']", 'click', function () {
    $("#link-heading-btn").removeClass('disabled').prop('disabled', false);
  });

  $(document).delegate("#heading_name", 'change', function () {
    $("#create-heading-btn").removeClass('disabled').prop('disabled', false);
  });
});