# FIXME: in progress, 2 problemi:
# - visualizzazione molto sballata di certi testi (vedi Porzio, marcatura "involontaria")
# - in certi casi parentesi uncinate non vengono visualizzate e "si mangiano" la parola racchiusa. Es.: <Lorem>
# 
# Cfr. http://jeff.jones.be/technology/articles/textile-filtering-with-redcloth/
# Cfr. sorgente RedCloth
# textilize_with_entities
#

=begin
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
=end