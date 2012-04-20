module UnitsHelper

  def prev_or_next_link(direction, object, action_name)
    icon = "<i class=\"icon-chevron-#{direction}\"></i>"
    classes = "btn pull-#{direction}"

    path = action_name == "show" ? unit_path(object) : edit_unit_path(object)

    if object
      link_to icon, path, :class => classes
    else
      link_to icon, "#", :class => classes + " disabled"
    end

  end

  def reorder_tag(tag, opts={})
    case tag
    when :hidden_field
      hidden_field_tag( "reorder_attributes[][#{opts[:param]}]", opts[:value], {:id => nil})
    when :label
      label_txt = opts[:txt] || ( opts[:table] ? "#{opts[:table]}.#{opts[:attr]}" : opts[:attr] )
      label_tag( "reorder_attributes[][use_for_order][#{opts[:attr]}]", label_txt )
    when :check_box
      check_box_tag "reorder_attributes[][use_for_order]", value = '1', checked = false,
        {:id => send(:sanitize_to_id, "reorder_attributes[][use_for_order][#{opts[:attr]}]")}
    when :direction_select
      select_tag  "reorder_attributes[][direction]",
        options_for_select([['crescente', 'asc'], ['decrescente', 'desc']], 'asc'),
        {:id => nil}
    end
  end

end