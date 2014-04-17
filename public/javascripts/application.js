/* Validare file js con jshint */

$(document).ready(function() {

  // Alerts
  setTimeout(function(){
    $(".alert-success").fadeOut('slow', function() {});
  }, 2000);

  // jQuery UI: Archimate defaults
  // OPTIMIZE: diventerà inutile una volta dismessi i dialog JqueryUI
  $.extend($.ui.dialog.prototype.options, {
    autoOpen: false,
    modal: true,
    position: ['center', 140],
    resizable: false,
    show: 'fade'
  });

  // BlockUI: Archimate defaults
  // OPTIMIZE: da rivedere + i18n

  $.blockUI.defaults.applyPlatformOpacityRules = false; // show overlay in Firefox on Linux
  $.blockUI.defaults.draggable = false;
  $.blockUI.defaults.overlayCSS.backgroundColor = "#000";
  $.blockUI.defaults.overlayCSS.opacity = 0.2;
  $.blockUI.defaults.centerX = true;
  $.blockUI.defaults.centerY = false;
  $.blockUI.defaults.css.top = '180px';
  $.blockUI.defaults.message = null;
  $.blockUI.defaults.baseZ = 9000; // z-index for the blocking overlay; default: 1000

  // DON'T GO AWAY WITHOUT SAVE

  $(function () {
    // FIXME: non innescare askConfirm per le form che non eseguono azioni di save (search, import, ecc.)
    $('form:not(".skip-prompt") :input').bind('change', function () {
      $("#fond-preview").addClass("disabled"); // solo in fonds/treeview
      askConfirm(true);
    });
    $('input[type="submit"]').click(function() {
      $("#fond-preview").removeClass("disabled");
      askConfirm(false);
    });
    // FIXME: verificare attentamente funzionamento askConfirm in fonds/treeview
    // FIXME: askConfirm si deve innescare anche quando si agisce sulle relations
    // (l'interazione con queste talvolta prescinde da elementi di form, ma si attua mediante link "aggiungi" / "rimuovi")
    // OPTIMIZE: modal al posto di browser dialog (?)

    function askConfirm(on) {
      window.onbeforeunload = (on) ? confirmMessage : null;
    }

    function confirmMessage() {
      return '';
    }

    window.onerror = UnspecifiedErrorHandler;
    function UnspecifiedErrorHandler() {
      return true;
    }
  });

  // Forms: prevent double-click of submit inputs (and buttons equivalent to submit inputs)
  $(document).on("click", 'input[type="submit"], button.submit', function(event){
    if ($(this).hasClass("disabled")) {
      return false;
    } else {
      $(this).clone().insertAfter($(this)).prop("disabled", true).addClass("disabled");
      $(this).hide();
    }
  });

  // FONDS

  function validatesPresenceOf(name) {
    if (name.replace(/\s/g, "") === "") {
      $(".inline-msg").show();
      return false;
    } else {
      return true;
    }
  }

  $("#create_fond").click(function() {
    var name = $("#fond_name").val();
    var group_id = $("#fond_group_id").val();
    var sequence_number = $("#fond_sequence_number").val();
    var validForm = true;
    validForm = validForm && validatesPresenceOf(name);

    if (validForm) {
      $.ajax({
        url: "/fonds/ajax_create",
        dataType: "json",
        type: "POST",
        data: '{"fond": { "name": "' + name + '", "group_id": "' + group_id + '", "sequence_number": "' + sequence_number + '"} }',
        processData: true,
        contentType: "application/json",
        success: function(data, textStatus, jqXHR){
          var final_status = jQuery.parseJSON(jqXHR.responseText);
          if (final_status.status === "failure") {
            return false;
          } else {
            window.location = "/fonds/" + final_status.id + "/treeview";
            $('#add_fond_modal').modal('hide');
          }
          $(":input","#add_fond_modal").val("");
          $(".inline-msg").hide();
          $(".alert").replaceWith("<div id=\"fond_form_error\"></div>");
        }
      });
    }
  });

  $(".close_fond").click(function() {
    $(":input","#add_fond_modal").val("");
    $(".inline-msg").hide();
    $(".alert").replaceWith("<div id=\"fond_form_error\"></div>");
  });

  // EDITORS

  $("#add-editor-modal").click(function(){
    $.get('/editors/modal_new').success(function(data){
      $('#add-editor-container').html(data);
      $('#add-editor-container #add-editor-dialog').modal("show");
    });
    return false;
  });

  $(document).delegate('#create-editor-btn', 'click', function(event){
    $.post('/editors/modal_create',
      $('#new-editor-form').serialize(),
      function(data){
        if (data.status === "success") {
          $('#add-editor-dialog').modal("hide");
        } else {
          $("#editor_form_error").
          html('<div class="alert alert-error"><a class="close" data-dismiss="alert">×</a>' + data.msg + '.</div>');
        }
      },'json');
    event.stopImmediatePropagation();
  });

  $(document).delegate(".datepicker", 'click', function(){
    $(this).removeClass('hasDatepicker').datepicker({
      dateFormat: 'yy-mm-dd',
      changeMonth: true,
      changeYear: true
    }).focus();
  });

  // UNITS
  $('#unit_tsk').change(function() {
    window.location = window.location.href.split('?')[0] + "?t=" + this.value;
  });

  $('#create_reference_number').click(function(){
    if($('#unit_folder_number').val() === "" || $('#unit_file_number').val() === "") {
      alert("I campi Busta e Fascicolo non devono essere vuoti");
      return false;
    }
    $("#unit_reference_number").attr("value","b. " + $('#unit_folder_number').val() + ", fasc. " +$('#unit_file_number').val());
    return false;
  });

  // SOURCES
  $('#source_source_type_code').change(function() {
    window.location = window.location.href.split('?')[0] + "?type=" + this.value;
  });

  // COMMON FEATURES and ARCHIDATE
  $('.disabled').attr("disabled", true);

  $(".archidate-wrapper").archidate();

  $('.autocomplete').archimate_autocomplete_setup();

  $("#template-selector").change(function(event){
    $("#template-text").val($(this).val());
  });

  // CLONE NESTED ATTRIBUTES
  // OPTIMIZE: la funzione clone può essere estratta e condivisa come quella di autocomplete

  $('form a.add_child').click( function() {
    var new_index = new Date().getTime();
    var data_assoc = $(this).attr('data-association');
    var new_fields_$ = $('#' + data_assoc).find('.fields:first').clone();

    new_fields_$.find('label, input, select, textarea')
    .attr('for', function(){
      if ($(this).attr('for')) {
        return $(this).attr('for').replace(/\d+/, new_index);
      }
    } )
    .attr('id', function(){
      if ($(this).attr('id')) {
        return $(this).attr('id').replace(/\d+/, new_index);
      }
    } )
    .attr('name', function(){
      if ($(this).attr('name')) {
        return $(this).attr('name').replace(/\d+/, new_index);
      }
    } );

    new_fields_$.find('input:text, select, input:file').attr('value', '');
    new_fields_$.find('input:checkbox').attr('checked', false).attr('aria-pressed', false);

    new_fields_$.find('select').each(function(){
      var options = $(this).find('option');
      options.removeAttr('selected');
      options.first().attr('selected', true);
    });

    new_fields_$.find('textarea').empty();

    new_fields_$.find('.autocomplete').archimate_autocomplete_setup();
    $(this).parent().before(new_fields_$);

  });

  $('.textile').markItUp(mySettings,{});

  // DIGITAL OBJECTS

  $("a.fancybox").fancybox({
    'padding': 5,
    'centerOnScroll': true
  });

  function fancyTitle(title, currentArray, currentIndex, currentOpts) {
    return '<span id="fancybox-title-over">' + (currentIndex + 1) + ' / ' + currentArray.length + '</span>';
  }

  $("a.fancybox-gallery").fancybox({
    'padding': 5,
    'titlePosition': 'over',
    'titleFormat': fancyTitle,
    'centerOnScroll': true
  });

  $("#digital-objects-warning").popover({
    title: "Oggetti digitali non disponibili",
    content: "Per accedere a questa funzionalità è necessario installare il programma ImageMagick.",
    placement: 'bottom'
  });

});

/*
  OPTIMIZE: quando c'è tempo e dopo attenta verifica, sostituire live() con delegate().
  "As of jQuery 1.7, the .live() method is deprecated. Use .on() to attach event handlers.
  Users of older versions of jQuery should use .delegate() in preference to .live()."
*/

