# Some customization for Module: WillPaginate::ViewHelpers
# Cfr. http://rdoc.info/github/mislav/will_paginate/master/WillPaginate/ViewHelpers:page_entries_info

# Monkey patch: set will_paginate default per_page to 20 instead of the default 30
ActiveRecord::Base.instance_eval do
  def per_page; 20; end
end

module WillPaginate

  module ViewHelpers

    def page_entries_info(collection, options = {})
      # TODO: i18n -> entry_name = "Scheda" o qualcosa di più raffinato. Vedremo

      if collection.total_pages < 2
        case collection.size
          when 0; ""
          when 1; ""
          else;   "<strong>#{collection.size}</strong> schede"
        end
      else
        %{Schede <strong>%s - %s</strong> di <strong>%s</strong> totali} % [
        number_with_delimiter(collection.offset + 1),
        number_with_delimiter(collection.offset + collection.length),
        number_with_delimiter(collection.total_entries)
        ]
      end
    end

    def display_page_entries_info(collection, options = {})
      if collection.size > 1
        '<div class="page-entries-info">' + page_entries_info(collection, options) + '</div>'
      end
    end

  end

  class BootstrapLinkRenderer < LinkRenderer
    # Override in Rails3 will be cleaner.
    # ==> https://gist.github.com/1248807
    # "Link renderer to be used with will_paginate to render links to work with Twitter Bootstrap"
    # See also: https://github.com/mislav/will_paginate/issues/158

    def to_html
      links = @options[:page_links] ? windowed_links : []

      links.unshift(page_link_or_span(@collection.previous_page, 'disabled prev', @options[:previous_label]))
      links.push(page_link_or_span(@collection.next_page, 'disabled next', @options[:next_label]))

      html = @template.content_tag(:ul, links.join(@options[:separator]))
      html = html.html_safe if html.respond_to? :html_safe
      @options[:container] ? @template.content_tag(:div, html, html_attributes) : html
    end

    def gap_marker
      text = @template.will_paginate_translate(:page_gap) { '&hellip;' }
      %(<li class="disabled"><a href="#">#{text}</a></li>)
    end

    protected

    def windowed_links
      prev = nil

      visible_page_numbers.inject [] do |links, n|
        links << gap_marker if prev and n > prev + 1
        links << page_link_or_span(n, 'active')
        prev = n
        links
      end
    end

    def page_link_or_span(page, span_class, text = nil)
      text ||= page.to_s
      text = text.html_safe if text.respond_to? :html_safe

      if page and page != current_page
         classnames = span_class && span_class.index(' ') && span_class.split(' ', 2).last
         page_link page, text, :class => classnames
       else
         page_span page, text, :class => span_class
       end
    end

    def page_link(page, text, attributes = {})
      @template.content_tag(:li, @template.link_to(text, url_for(page)), attributes)
    end

    def page_span(page, text, attributes = {})
      @template.content_tag(:li, @template.link_to(text, "#"), attributes)
    end

  end

end

# Override default options on the global level
WillPaginate::ViewHelpers.pagination_options[:previous_label] = '&#8592;'
WillPaginate::ViewHelpers.pagination_options[:next_label] = '&#8594;'
WillPaginate::ViewHelpers.pagination_options[:inner_window] = 2 # Default: 4
WillPaginate::ViewHelpers.pagination_options[:outer_window] = 0 # Default: 1
WillPaginate::ViewHelpers.pagination_options[:renderer] = 'WillPaginate::BootstrapLinkRenderer'
