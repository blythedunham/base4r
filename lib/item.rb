# Base4R is a ruby interface to Google Base
# Copyright 2007, 2008 Dan Dukeson

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

require 'rexml/document'

module Base4R
  module ItemAttributeMethods
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend,  ClassMethods
    end
    module ClassMethods
      #set the attribute definitions and define setters and getters
      def define_attributes(options)
        @attribute_definitions ||= {}
        @attribute_definitions.update(options)
        options.each {|k,v| define_setter_method(k, v)}
      end

      #define setter methods on the object
      def define_setter_method(method, options={})
        class_eval <<-EOS, __FILE__, __LINE__
          def set_#{method}(value); add_attribute(:#{method}, value); end
          alias_method "#{method}=", "set_#{method}"
        EOS
      end

      # Define setter and getter methods. The example will define author_name and author_name=
      #  define_child_method :author, :name
      def define_child_accessor(parent, child)
        class_eval <<-EOF
          def #{parent}_#{child};     child_value(:#{parent}, :#{child});        end
          def #{parent}_#{child}=(v); set_child_value(:#{parent}, :#{child}, v); end
        EOF
      end

      # return all actual and inherited definitions
      def attribute_definitions#:nodoc
        @all_attribute_definitions ||=
          (superclass.respond_to?(:attribute_definitions) ?
            superclass.attribute_definitions :
            {}).merge(@attribute_definitions||{})
      end

      # return the attribute definition for a specific attribute
      def attribute_definition(name)#:nodoc:
        attribute_definitions[name.to_sym]
      end
    end
    module InstanceMethods

      def child_value(parent_name, child_name)
        parent = get_attribute(parent_name)
        child = parent.send(child_name) if parent
        child.value if child
      end

      def set_child_value(parent_name, child_name, value)
        parent = get_attribute(parent_name)||add_attribute(parent_name, nil)
        parent.add_child(child_name, value)
      end

      # return the attribute objects that correspond to this element
      def get_attributes(name); attributes.select {|a| a.name.to_s == name.to_s }; end
      def get_attribute(name);  attributes.detect {|a| a.name.to_s == name.to_s }; end

      # set the google private flag for the specified attribute
      #  item.set_attribute_private :location
      def set_attribute_private(name, is_private=true)
         attributes.each { |attr| attr.private_attribute = is_private if name.to_s == attr.name.to_s }
      end

      # Add the attribute to the item
      #  item.add_attribute :price, :value => 5, :units => 'USD'
      #  item.add_attribute :item_type, 'Products'
      def add_attribute(attribute_name, value)
        # get the options passed in from the value
        options = options_from_value(value)

        attr_def = self.class.attribute_definition(attribute_name)||{}
        attr_class =  type_to_attribute_class(options[:type]||attr_def[:type]||:text)

        # add a namespace param if there is one
        options[:namespace] ||= attr_def[:namespace] if attr_def.has_key?(:namespace)

        #raise options.inspect if attribute_name.to_s == 'customme'
        # create a new attribute
        attr = attr_class.new(attr_def[:name]||attribute_name, options)

        @attributes << attr
        attr
      end
      # convert type field to the corresponding Attribute class
      # Example :text is AttributeText
      def type_to_attribute_class(type_name)#:nodoc:
        return type_name if type_name.is_a?(Attribute)
 
        Base4R.const_get "#{type_name.to_s.gsub(/(?:^|_)(.)/) { $1.upcase } }Attribute"
      end
    end
  end


  # Item describes a single entry that will be or is already stored in Google Base
  class Item

    include ItemAttributeMethods

    # array of Attribute objects that describe the Item
    attr_accessor :attributes
    
    # Title of the Item
    attr_accessor :title

    # ID of this Item as assigned by Google
    attr_accessor :base_id

    # unique alphnumeric identifier for the item - e.g. your internal ID code. 
    # IMPORTANT: Once you submit an item with a unique id, this identifier must 
    # not change when you send in a new data feed. Each item must retain the same 
    # id in subsequent feeds.
    attr_accessor :unique_id

    attr_accessor :draft

    define_child_accessor :author, :name
    define_child_accessor :author, :email

    def options_from_value(value, default_options={})#:nodoc:
      default_options.merge(value.is_a?(Hash) ? value : {:value => value})
    end

    # Represents this Item as Atom XML which is the format required by the Base API. 
    def to_xml
      
      doc = REXML::Document.new('<?xml version="1.0" ?>')

      entry = doc.add_element 'entry',
                              'xmlns'=>'http://www.w3.org/2005/Atom', 
                              'xmlns:g' => 'http://base.google.com/ns/1.0',
                              'xmlns:app'=>'http://purl.org/atom/app#',
                              'xmlns:gm'=>'http://base.google.com/ns-metadata/1.0'

      #bjd: not sure why these are instance variables but others are not
      #if @author_name || @author_email
      #  AuthorAttribute.to_xml(entry, :author, nil, :email => @author_email, :name => @author_name)
      #end

      entry.add_element 'category',
                        'scheme'=>'http://www.google.com/type',
                        'term' => 'googlebase.item'

      if draft?
        goog_control = entry.add_element('app:control', 'xmlns:app'=>'http://purl.org/atom/app#')
        goog_control.add_element('app:draft').text = 'yes'
      end

      entry.add_element('title').text= @title

      @attributes.each do |attr|
        attr.to_xml(entry)
      end

      doc
    end

    
    def draft=(value)
      @draft = value.is_a?(TrueClass) || value.to_s.downcase == 'yes'
    end

    def draft?; @draft; end
  end


  #
  # Item with a minimal set of Attributes, extend for specific Item Types
  # 
  #
  class UniversalItem < Item
    define_attributes(
      :description    => nil,
      :contact_phone  => nil,
      :item_type      => nil,
      :item_language  => nil,
      :target_country => nil,
      :application    => nil,
      :link           => { :type => :url, :namespace => nil },
      :expiration_date=> { :type => :dateTime },
      :label          => nil,
      :unique_id      => { :name => :id },
      :author         => { :value => nil, :namespace => nil, :type => :author },
      :image_link     => { :type => :bare },
      :location       => { :type => :location}
    )

    # Create a new UniversalItem, with _unique_id_, created by _author_name_ who's email is _author_email_, 
    # described by _description_, found at URL _link_, entitled _title_, phone number is 
    # _contact_phone_, item type is _item_type_, _target_country_ e.g. 'GB', _item_language_ e.g. 'EN'
    #
    # Args can also be a hash of attributes
    def initialize(*args)
      options = initialize_args_to_options(args)
      #allow an option to specify which columns are private
      private_attributes = [options.delete(:private_attributes)].flatten.inject([]){|list, val| list << val.to_s if val; list}.uniq

      @title        = options.delete(:title)
      self.draft    = options.delete(:draft)
      @attributes = []

      options.each do |key, value|
        v = options_from_value(value, :private_attribute => private_attributes.include?(key.to_s))
        #back support for author name and email
        if value && [:author_name, :author_email].include?(key.to_sym)
          send "#{key}=", value
        else
          add_attribute key, v
        end
      end
    end

    protected
    # convert old style input args to new style
    def initialize_args_to_options(args)#:nodoc:
      options = if args.first.is_a?(Hash)
        args.first.dup
      else
        %w(unique_id author_name author_email description link title contact_phone item_type target_country item_lang).inject({}) {|map, option|
          map[option.to_sym] = args.shift
          map
        }
      end
    end

    public

    # Define for backwards compatibility
    alias_method :add_image_link, :set_image_link
    alias_method :add_label,      :set_label
    alias_method :context=,       :set_description
    alias_method :item_lang=,     :set_item_language
  end

  # ProductItem is a standard item type. This class includes some of the attributes that are
  # suggested or required for the Product item type.
  #
  class ProductItem < UniversalItem


    define_attributes({
      :condition      => nil,
      :will_deliver   => {:type => :boolean },
      :delivery_notes => nil,
      :department     => nil,
      :payment        => nil,
      :payment_notes  => nil,
      :pickup         => {:type => :boolean },
      :price_type     => nil,
      :price_units    => nil,
      :price          => {:type => :float_unit},
      :image_like     => { :type => :bare },
      :quantity       => { :type => :int }})

    #rewrite to satisfy old style of price setting
    #  set_price 5, 'usd'
    #  set_price :value => 5, :units => 'usd'
    def price(price_amount, price_units=nil)
      add_attribute :price, :value => price_amount, :units => price_units
    end

    alias_method :add_payment, :payment=
    alias_method :add_custom, :add_attribute
    alias_method :add_custom_test, :add_attribute
  end

end
