#   Copyright (c) 2012-2017, Fairmondo eG.  This file is
#   licensed under the GNU Affero General Public License version 3 or later.
#   See the COPYRIGHT file for details.

# We cannot namespace them properly as formtastic's lookup chain would not find them
# see  lib/formtastic/helpers/input_helper.rb
# module Fairtastic
#  module Inputs
class PlainCheckBoxInput < Formtastic::Inputs::BooleanInput
  def label_with_nested_checkbox
    builder.label(
      method,
      label_text_with_embedded_checkbox,
      label_html_options.tap do |options|
        options[:class] << 'checkbox'
      end
    )
  end

  def check_box_html
    opts = input_html_options
    if options[:js_toggle]
      css_class = options[:js_toggle].is_a?(String) ? options[:js_toggle] : "#{method}-checked"
      opts['data-select-toggle'] ||= css_class
    end
    template.check_box_tag("#{object_name}[#{method}]", checked_value, checked?, opts)
  end

  def wrapper_classes_raw
    super << ' boolean'
  end
end
