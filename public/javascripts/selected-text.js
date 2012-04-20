jQuery.fn.selectedText = function(options){
  var settings = $.extend( {
    }, options);

  var text = '';

  this.each(function() {

    /*this.getSelectedText = function() {
      return settings.text;
    };*/

    if(this.is("textarea") || this.is("input")) {
      var input = document.getElementById(this.attr('id'));
      var start = input.selectionStart;
      var end = input.selectionEnd;
      text = this.val().substring(start,end);
    } else {
      if(window.getSelection){
        text = window.getSelection();
      } else if(document.getSelection){
        text = document.getSelection();
      } else if(document.selection){
        settings.text = document.selection.createRange().text;
      }
    }
    return text;
  });
};


