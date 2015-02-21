module ApplicationHelper

  # AssetTagHelper
  def default_stylesheets
    stylesheet_link_tag "bootstrap.min", "jquery-ui-1.8.18", "master", "markitup", "fancybox",
      :cache => "/assets/application"
  end

  # LayoutHelper
  def body_id
    actions = %w[treeview gridview]
    body_id = actions.include?(action_name) ? ' id="' + action_name + '"' : nil
  end

  def container_id
    actions = %w[new create show edit update new_iccd edit_iccd show_iccd]
    container_id = actions.include?(action_name) ? ' id="record-container"' : nil
  end

  def container_class(value)
    content_for(:container_class) { value }
  end

  def row_class(container_class)
    container_class == "container-fluid" ? "row-fluid" : "row"
  end

  # StatusBarContext
  def path_separator
    '<span class="divider">/</span>'
  end

  def status_bar_context
    label = case action_name
    when 'index' then nil
    when 'list' then nil
    when 'new' then 'new_record'
    when 'edit', 'treeview' then 'edit_record'
    when 'show' then 'show_record'
    end

    context = ["#{t(controller_name)}"]
    context << "#{t(label)}" unless label.nil?
    context.join(path_separator)
  end

  # UrlHelper
  def active_if(condition)
    ' class ="active"' if condition == true
  end

  def link_to_index(name, target)
    link_to(name, target, :class => "to-index")
  end

  def edit_object_path(object)
    edit_or_treeview = controller_name == "fonds" ? "treeview" : "edit"
    send("#{edit_or_treeview}_#{object.class.name.underscore.downcase}_path", object)
  end

  def add_child_link(name, association)
    link_to(name, "javascript:void(0)", :class => "add_child", :"data-association" => association)
  end

  def link_to_digital_objects_by_count(digital_objects_count, name, object, html_options = {})
    target_link = if digital_objects_count > 0
      polymorphic_path([object, "digital_objects"])
    else
      new_polymorphic_path([object, "digital_object"])
    end
    link_to(name, target_link, html_options)
  end

  # Sortable Columns
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = (column == sort_column) ? "current #{sort_direction}" : nil
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    link_to title, params.merge({:sort => column, :direction => direction}), {:class => css_class}
  end

  # Inline CSS
  def css_size_by_cookie(property, default_value, increment = 0)
    if cookies[property.to_sym].blank?
      default_value + "px"
    else
      (cookies[property.to_sym].to_i + increment).to_s + "px"
    end
  end

  # FormOptionsHelper
  def terms_select(f, list_name, options={}, html_options={})
    attribute = list_name.split('.')[1]
    f.select(attribute, @terms.select {|l| l.vocabulary_name == "#{list_name}"}.map {|a| [ t(a.term_key), a.term_value ]}, options, html_options)
  end

  def iccd_terms_select(f, list_name, term_scope = nil, options={}, html_options={})
    attribute = list_name.split('.')[1]
    f.select(attribute, @iccd_terms.select {|l| l.vocabulary_name == "#{list_name}" && l.term_scope == term_scope}.map {|a| [ a.term_key, a.term_value ]}, options, html_options)
  end

  # Options for select heading_types
  def heading_types
    options_for_select(@terms.select {|l| l.vocabulary_name == "headings.heading_type"}.map {|a| [a.term_value, a.term_value]})
  end

  def required_marker
    "&nbsp;*&nbsp;"
  end

  # ShowHelpers

  # BlankField
  def blank_field
    '<span class="blank">' + t('blank_field') + '</span>'
  end

  # WarningField
  def warning_field
    '<span class="warning">' + t('warning_field') + '</span>'
  end

  # Show actions
  def build_or_retrieve(collection, attributes = {})
    if collection.blank?
      collection.build(attributes = {})
    else
      collection
    end
  end

  # ShowValue
  def show_value(value, options={})
    if value.present?
      options == "t" ? t(value) : value
    else
      blank_field
    end
  end

  # ShowItem
  def show_item(item, options=['', ''], translate=nil)
    if item.present?
      string = translate.present? ? t(item) : item
      options[0] + string + options[1]
    else
      ""
    end
  end

  # ShowEditor
  def show_editor(object)
    string = object.name
    string += " (#{object.qualifier})" unless object.qualifier.blank?
    string += ", #{object.editing_type}" unless object.editing_type.blank?
    string += ", #{l object.edited_at, :format => :long}" unless object.edited_at.blank?
    string
  end

  # NormalizeDateForEAD
  def normalize_date_for_ead(event)
    if event.equal_bounds?
      "#{normalize_bound event.start_date_from, event.start_date_format}"
    else
      "#{normalize_bound event.start_date_from, event.start_date_format}/#{normalize_bound event.end_date_from, event.end_date_format}"
    end
  end

  def normalize_bound(date, format)
    case format
    when 'Y'
      date.year.to_s
    when 'O'
      String.new
    else
      date.to_s.underscore.camelize
    end
  end

  # TextHelpers
  # Unescapes the entities for special characters that have been escaped by RedCloth.
  # For example: fond.description of "Archivio storico Arnoldo Mondadori Editore - AME"
  # OPTIMIZE: dubbio che sia ancora utile. Verificare !
  def textilize_with_entities(text)
    textilize(text).gsub("&amp;#", "&#")
  end

  def formatted_source(source)
    if source.use_legacy?
      h source.legacy_description.gsub(/<C>|<N>|<T>|<CR>/i, '')
    else
      [
        h(source.author),
        (source.title.present? ? content_tag(:em, h(source.title)) : nil),
        h(source.place),
        h(source.publisher),
        h(source.date_string)
      ].
        delete_if{|fragment| fragment.blank?}.
        join(", ")
    end
  end

  def formatted_custodian_building(building)
    [
      building.address,
      building.postcode,
      building.city,
      building.country
    ].
      delete_if{|fragment| fragment.blank?}.
      join(" ")
  end

  def inline_short_sources(sources)
    text = []
    sources.each do |source|
      text << "[<em>#{source.short_title}</em>]"
    end
    text.join(", ")
  end

  # TODO: [1.x] rifare relations Required options:
  # - <tt>:f</tt> => main entity form builder
  # - <tt>:related_to</tt> => a symbol of the name of the target association,
  #   example :creators if Fond has many creators through :rel_creator_fonds
  # - <tt>:related_through</tt> => a collection of the current association
  #   records, example @rel_creator_fonds (array of active record objects), if
  #   Fond has many creators through :rel_creator_fonds; if this local is not
  #   specified, an instance variable will be used, based on the name of the
  #   through association
  # - <tt>:selected_label</tt> => a lambda used to populate the visible value of
  #   every single related object; the association record is yielded to the
  #   block; this is required because in general retrieving the shown value is
  #   not trivial, and is specific to every type of association example: lambda
  #   { |through_record| through_record.creator.preferred_name.try(:name) }
  # - <tt>:available_related</tt> => the number of records available to be added
  #   to the relation
  #
  # Other requirements:
  # - the target model (Creator, for example), must have a method (or,
  #   preferably, a scope) that accepts a search string, which is given in
  #   params[:term]
  #
  # Other options with defaults:
  # - <tt>:foreign_key</tt>, if provided, it will override the default (that is
  #   association_foreign_key)
  # - <tt>:excluded_ids</tt>, an id or an array of ids; if provided the records
  #   with these ids will be filtered out, and not be shown in the autocomplete
  #   or in the suggested list, even if present in the results;
  # - <tt>:cardinality</tt>, default 'unlimited', can be set at 1
  # - <tt>:suggested_list</tt>, if provided, will be used to create a list of
  #   preset suggestions
  # - <tt>:suggested_label</tt>, same principle of selected_label
  # - <tt>:suggested_threshold</tt>, required if :suggested_list have been
  #   specified, if the suggested_list size is greater than this, autocomplete
  #   will be used
  # - <tt>:autocompletion_controller</tt>, default is the same of the
  #   "related_to" option (example: "creators")
  # - <tt>:autocompletion_action</tt>, default is "list"; the action must return
  #   a json response, with an array of objects, and each object must have the
  #   property "id" and "value"; id is the id of the target association
  #   (creator, for example)
  def finalize_relation_options(f, relation_options)
    opts = relation_options
    # Parameters setup, based on given locals
    #
    # Example: related_to => :creators
    opts[:association]                = f.object.class.reflect_on_association(opts[:related_to].to_sym)
    # => Creator
    opts[:related_model]              = opts[:association].klass
    # => "creator_id"
    opts[:foreign_key]                ||= opts[:association].association_foreign_key
    opts[:through_association]        = opts[:association].through_reflection
    # => :rel_creator_fonds
    opts[:through_association_name]   = opts[:through_association].name
    # => RelCreatorFond
    opts[:through_model]              = opts[:through_association].klass
    # => rel_creator_fond (new_record? => true)
    opts[:through_record]             = opts[:through_model].new # to support the template item
    # => :creator
    opts[:source_association_name]    = opts[:association].source_reflection.name
    # => @rel_creator_fonds
    # default available, but should always be specified to use local variables
    # instead of inherited instance variables
    opts[:related_through]            ||= instance_variable_get("@#{opts[:source_association_name]}".to_sym)
    # => "creators"
    opts[:autocompletion_controller]  ||= opts[:related_to].to_s
    opts[:autocompletion_action]      ||= "list"
    opts[:variant]                    ||= 'autocomplete'
    opts[:suggested_threshold]        ||= nil
    opts[:excluded_ids]               ||= []
    opts[:suggested_list]             ||= nil
    opts[:cardinality]                ||= 'unlimited'
    opts[:available_related]          ||= 0
    opts[:selected_label]             ||= nil
    opts[:selected_label_short]       ||= nil
    opts[:selected_label_full]        ||= nil
    opts[:child_index]                ||= '_new_' # to support the template item
    opts[:fields_before]              ||= nil
    opts[:fields_after]               ||= nil

    opts
  end

  def default_relation_options_for( f, related_to, related_through )
    {
      :related_to => related_to.to_sym,
      :related_through => related_through,
      :suggested_list => instance_variable_get("@suggested_#{related_to}".to_sym),
      :suggested_threshold => instance_variable_get("@#{related_to}_threshold".to_sym),
      :available_related => instance_variable_get("@available_#{related_to}".to_sym),
      :excluded_ids => f.object.send("#{related_to.to_s.singularize}_ids")
    }
  end

  def render_relation_for( f, related_to, related_through, opts={} )
    render  :partial => "shared/relations/relation",
      :locals => {
      :f => f,
      :relation_options =>  default_relation_options_for( f, related_to, related_through ).
        merge(opts)
    }
  end

end

