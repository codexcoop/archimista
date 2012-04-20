$(document).ready(function(){

  var source_type_selected = $("#source_source_type_code option:selected").val();    
  
  switch (source_type_selected) {
    case "1": 
      $("#source-subtype-code").show();
      $("#source-finding-aid-valid").hide();
      $("#source-finding-aid-published").hide();
      $("#source-author").show();  
      $("#source-editor").show();
      $("#source-publisher").show();
      $("#source-author-label").text("Autore"); 
      $("#source-related-item").show();
      $("#source-related-item-specs").show(); 
      $("#side-secondary-actions").remove();
      $("#source-place").show();
    break;
    case "2": 
      $("#source-subtype-code").show(); 
      $("#source-finding-aid-valid").show();
      $("#source-finding-aid-published").show();
      $("#source-author").show();
      $("#source-editor").show();
      $("#source-publisher").show();
      $("#souce-label-editor").show(); 
      $("#source-author-label").text("Autore");
      $("#source-related-item").hide(); 
      $("#source-related-item-specs").hide(); 
      $("#side-secondary-actions").remove();
      $("#source-place").show();
    break; 
    case "3":
      $("#source-subtype-code").hide(); 
      $("#source-finding-aid-valid").hide();
      $("#source-finding-aid-published").hide();
      $("#source-author").hide();
      $("#source-editor").hide();
      $("#source-publisher").hide();
      $("#source-related-item").hide();
      $("#source-related-item-specs").hide(); 
      $("#side-secondary-actions").remove();
      $("#source-place").hide();
    break;
    case "4":
      $("#source-subtype-code").hide(); 
      $("#source-finding-aid-valid").hide();
      $("#source-finding-aid-published").hide();
      $("#source-author").show();   
      $("#source-editor").hide();
      $("#source-publisher").hide();
      $("#source-author-label").text("Autorità emanante");
      $("#source-place-label").text("Luogo");
      $("#source-related-item").hide();
      $("#source-related-item-specs").hide(); 
      $("#side-secondary-actions").remove(); 
      $("#source-place").show();
    break;
    default:
  }
});
