# OPTIMIZE: valutare se necessario ulteriore intervento
# Vedi:
# - helpers/application_helper.rb: metodi textilize e textilize_with_entities
# - http://jeff.jones.be/technology/articles/textile-filtering-with-redcloth/
# - sorgente RedCloth

module RedCloth::Formatters::HTML
  include RedCloth::Formatters::Base

  def after_transform(text)
    text.chomp!
    clean_html(text, ALLOWED_TAGS)
  end

  ALLOWED_TAGS = {
    'br' => [],
    'strong' => nil,
    'em' => nil,
    'ol' => nil,
    'ul' => nil,
    'li' => nil,
    'p' => nil
  }

end
