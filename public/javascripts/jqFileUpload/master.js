/* https://github.com/blueimp/jQuery-File-Upload/wiki */

$(function () {

  var added = 0;
  var completed = 0;

  $('#fileupload').fileupload({
    sequentialUploads: true,
    maxFileSize: 8192000,
    previewSourceMaxFileSize: 81920000,
    previewMaxWidth: 130,
    previewMaxHeight: 130,
    previewAsCanvas: false,
    acceptFileTypes: /(\.|\/)(jpe?g|pdf)$/i,
    previewSourceFileTypes: /^image\/(jp?eg)$|^application\/pdf$/
  });

  $('#fileupload').bind('fileuploadsubmit', function (e, data) {
    var inputs = data.context.find(':input');
    data.formData = inputs.serializeArray();
  });

  $('#fileupload').bind('fileuploadadded', function (e, data) {
    $('#btn-start, #btn-cancel').prop('disabled', false).removeClass('disabled');
    if ($('#fileupload-status').is(':visible')) { $('#fileupload-status').hide(); }
  });

  $('#fileupload').bind('fileuploadadd', function (e, data) {
    added += 1;
  });

  $('#fileupload').bind('fileuploadcompleted', function (e, data) {
    completed += 1;
    $('#btn-delete, #checkbox-delete').prop('disabled', false).removeClass('disabled');
    if ((added - completed) === 0) {
      $("#btn-start, #btn-cancel").prop('disabled', true).addClass('disabled');
      $('#fileupload-status').show();
    }
  });

  $('#fileupload').bind('fileuploaddestroyed', function (e, data) {
    $('#btn-delete, #checkbox-delete').prop('disabled', true).addClass('disabled');
    if ($('#fileupload-status').is(':visible')) { $('#fileupload-status').hide(); }
  });

  $(document).on("click", "#btn-cancel", function(e) {
    $("#btn-start, #btn-cancel").prop('disabled', true).addClass('disabled');
  });

  $(document).on("click", "button.cancel", function(e) {
    added -= 1;
    if (added === 0) { $('[id^=btn-]').prop('disabled', true).addClass('disabled'); }
  });

  $(document).on("click", "#header a", function(e){
    if ((added - completed) > 0) {
      e.preventDefault();
      $("#pending-number").text(added - completed);
      $('#pending').modal('show');
    }
  });

  $(document).on("click", "a.fancybox-live", function(e) {
    e.preventDefault();
    $.fancybox({
      href: this.href,
      type: 'image',
      'padding': 5,
      'centerOnScroll': true
    });
  });
});
