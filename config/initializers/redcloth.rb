# - http://jeff.jones.be/technology/articles/textile-filtering-with-redcloth/
#
# The methods patch_in and patch_out are intended to fix some bugs found in RedCloth 4.2.9.
# Examples of strings not correctly rendered (before patching):
#
#   L'_Apocalisse_
#   L’_età dell'oro_
#   Zandonai (_Giulietta e Romeo_, 1921), Alfano (_Madonna Imperia_, 1927)
#   _Atti degli Apostoli_, l'_Apocalisse_
#

module RedCloth::Formatters::HTML
  include RedCloth::Formatters::Base

  def patch_in(text)
    pairs = {
      '>' => '&gt;',
      '<' => '&lt;',
      "[" => "&#91;",
      "]" => "&#93;",
      "'" => "&#39;",
      "’" => "&#8217;",
      "(_" => "&#40; _",
      "_," => "_ &#44;"
    }
    pairs.each {|k, v| text.gsub!(k, v) }
  end

  def before_transform(text)
    patch_in(text)
    clean_html(text) if sanitize_html
  end

  def patch_out(text)
    pairs = {
      "&#40; <em>" => "(<em>",
      "</em> &#44;" => "</em>,"
    }
    pairs.each {|k, v| text.gsub!(k, v) }
  end

  def after_transform(text)
    patch_out(text)
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
