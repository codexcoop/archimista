PDFKit.configure do |config|
  config.wkhtmltopdf = '/usr/local/bin/wkhtmltopdf'
  config.default_options = {
    :page_size => 'A4',
    :margin_top    => '3cm',
    :margin_right  => '3cm',
    :margin_bottom => '3cm',
    :margin_left   => '3cm',
    :print_media_type => true,
    :disable_smart_shrinking => true,
    :encoding => "UTF-8"
  }
end

