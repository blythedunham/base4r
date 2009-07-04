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

#
# following taken from http://code.google.com/apis/base/starting-out.html
# 
# There are some limitations on how long your attribute names and values can be and how many you can use:

#     * titles: between 3-1000 characters
#     * attributes:
#           o names: 30 characters
#           o attribute text: 1000 characters, including spaces
#           o total number permitted: 30 per item
#     * labels:
#           o names: 40 characters
#           o total number permitted: 10 per item
#     * URL length: 1000

module Base4R

  module AdditionalXmlAttributeMethods
    def self.included(base)
      base.send :extend, ClassMethods
    end
    module ClassMethods
      def define_xml_attribute(name, value)
        @xml_attributes||={}
        @xml_attributes[name.to_s] = value
      end

      def xml_attributes; @xml_attributes||={}; end
    end

    def additional_xml_attribute_map
      self.class.xml_attributes.merge(xml_attributes||{}).inject({}) do |map, (k,v)|
        map[k] = xml_attribute_value(v)
        map
      end
    end

    def xml_attribute_value(v)
      v.is_a?(Proc) ? v.call(self) : v.to_s
    end

    def xml_attributes; options[:xml_attributes]||{}; end

  end

  module ChildAttributeMethods
    def self.included(base)
      base.send :extend,  ClassMethods
    end

    module ClassMethods
      def child_attribute(attr, options={})
        default_child_options[attr.to_sym] = options
        class_eval <<-EOS
          def child_#{attr}; children[:#{attr}]; end
          def child_#{attr}=(v); add_child(:#{attr}, v); end
          def #{attr}_value; #{attr}.value; end
          def #{attr}_value=(v); #{attr}.value = v; end
        EOS
      end
      def default_children_names; default_child_options.keys; end
      def default_child_options; @default_child_options||={}; end
    end

    protected
    # Add default children (defined) if data specified
    def add_default_children
      child_data = options.merge(options[:children]||{})
      self.class.default_children_names.concat((options[:children]||{}).keys).uniq.each do |child_name|
        add_child(child_name, child_data[child_name.to_sym]) if child_data.has_key?(child_name.to_sym)
      end
    end

    public
    # Add a custom prebuilt child
    # +attribute+ - an item of class +Attribute+
    #   shipping_attribute.add_custom_child(BareAttribute.new(:region, 'WA'))
    def add_child_attribute(attribute)
      children_map[attribute.name.to_sym] = attribute
    end

    # add a child. The accepted arguments are the same as initializing a new +Attribute+
    #   shipping_attribute.add_child(:region, 'WA')
    #   shipping_attribute.add_child(:region, :value => 'WA', :namespace => :g)
    def add_child(*args)
      #parse out the options specified here into keys
      parsed_options = options_from_args(args, :skip_defaults => true)

      child_name = parsed_options[:name].to_sym

      # merge the default options with the extra options with the namespace, name, type options
      child_options = (self.class.default_child_options[child_name]||{}).merge(parsed_options)
      klass = child_options.delete(:klass)||BareAttribute

      children_map[child_name] = klass.new(child_options)
    end

    #get a specific child
    def child(child_name); children_map[child_name.to_sym]; end

    # a map of all the children names to Attribute class values
    def children_map; @children_map||={}; end
    # All the children Attribute objects
    def children;       children_map.values; end
    # All the names of the children
    def children_names; children_map.keys;   end
  end


  # Attributes are typed key-value pairs that describe content. Attributes describe the
  # Base Item. Client code should use subclasses of Attribute such as TextAttribute, 
  # BareAttribute, DateTimeAttribute, IntAttribute, FloatUnitAttribute, UrlAttribute, 
  # LocationAttribute, BooleanAttribute. 
  # Each of these can represent themselves as required by the Atom format.
  class Attribute

    attr_accessor :name
    attr_accessor :value
    attr_accessor :namespace
    attr_accessor :options
    attr_accessor :private_attribute

    include ChildAttributeMethods
    include AdditionalXmlAttributeMethods

    # Represent this Attribute as an XML element that is a child of _parent_.
    def to_xml(parent, options={})

      
      return if value.nil? && children.empty? && !options[:force].is_a?(TrueClass)


 
      el = parent.add_element(calc_el_name)
      
      el.add_attribute('type', type_name)   if type_name && !type_name.empty?
      el.add_attribute('access', 'private') if private_attribute?




      #add additional attributes like href=http://meh.com
      additional_xml_attribute_map.each { |k,v| el.add_attribute(k.to_s, v.to_s) if v }

      el.text = value.to_s if value

      children.each {|child| child.to_xml(el) }
      el
    end

    def private_attribute?; private_attribute.is_a?(TrueClass); end

    def type_name=(value); @type_name=value.to_s; end

    # the type name for this attribute
    def type_name; @type_name || self.class.type_name; end

    class << self
      # keep this pure ruby instead of using rails stuff
      def type_name
        self.to_s.gsub(/^Base4R::(\w)(\w*)Attribute$/) { "#{$1.downcase}#{$2}" }
      end
      # Create an xml object with this
      #   BareAttribute.new(parent, :myattr, 'love', :private_attribute => true)
      def to_xml(parent, name, value, options={})
        new( name, value, options).to_xml(parent)
      end
    end

    protected

    # * +name+ - the name of the attribute
    # * +value+ - the value of the attribute
    # * +args+ - can be the namespace (default to :g) or the options
    # ===Options
    # <tt>:namespace</tt> - new way to specify namespace
    # <tt>:private_attribute</tt> - default false. set true if this is private (set attribute access = private)
    # <tt>:additional_attributes</tt - map of additional attribute decorations name/value pairs
    def initialize(*args)

      options_from_args(args, :set_instance => true)

      type_name = options.delete(:type_name) if options.has_key?(:type_name)

      @private_attribute = options.delete(:private_attribute).is_a?(TrueClass)
      add_default_children #create the children attributes if any
    end

    # arguments can work like
    # name, value, namespace =:g, options={}
    # name, value, options={}
    # name, options={}
    def options_from_args(args, parse_options={})#:nodoc:

      # if the last argument is a hash, use it for the options
      option_map = args.last.is_a?(Hash) ? args.pop : {}

      parsed_option_map = [:name, :value, :namespace].inject({}) do |map, v|
        #first pop the value if any are left
        val = if args.any?
          args.shift

        #check for the value in the option map
        elsif option_map.has_key?(v)
          option_map.delete(v)

        #default namespace to :g
        elsif v == :namespace && !parse_options[:skip_defaults].is_a?(TrueClass)
          :g
        else
          :__SKIP_THIS_VAR__
        end

        map[v] = val unless val == :__SKIP_THIS_VAR__
        map
      end

      if parse_options[:set_instance]
        parsed_option_map.each { |name, val| instance_variable_set "@#{name}", val }
        @options = option_map
      end

      option_map.merge(parsed_option_map)

    end
    def calc_el_name; namespace ? "#{namespace}:#{name}" : name.to_s; end
  end

  # TextAttribute is a simple string.x
  class TextAttribute < Attribute; end

  # BareAttribute is a string attribute but is in the google namespace
  class BareAttribute < Attribute
    def type_name; @type_name; end
  end

  # UrlAttribute represents a URL
  class UrlAttribute < Attribute
    define_xml_attribute :rel,  :alternate
    define_xml_attribute :type, 'text/html'
    define_xml_attribute :href, Proc.new{|attr| attr.value }

    def to_xml(parent, options={})
      el = super(parent, options.merge(:force => true))
      el.text = nil
      el
    end
  end

  # DateTimeAttribute represents a DateTime
  class DateTimeAttribute < Attribute; end

  # IntAttribute represents an Integer
  class IntAttribute < Attribute; end

  # BooleanAttribute represents a Boolean
  class BooleanAttribute < Attribute; end

  class SomethingUnits < Attribute
    attr_accessor :units
    attr_accessor :value_without_units

    def initialize(*args)
      super(*args)
      @units = options.delete(:units)
      @value_without_units = @value
    end

    def value; "#{@value_without_units} #{@units}".strip;  end
    def value=(v); @value_without_units, @units = v.split; end
  end

  class NumberUnits < SomethingUnits; end

  # FloatUnitAttribute represents a floating-point property with units.
  class FloatUnitAttribute < SomethingUnits
    # Create a FloatUnitAttribute with _name_, a quantity of _number_, described in _units_ and in _namespace_
    # old definition:
    #   FloatUnitAttribute.new(name, number, units, namespace)
    # new definition:
    #   FloatUnitAttribute.new(name, number, options={})
    #   FloatUnitAttribute.new(:price, 50, :units => :USD, :namespace => :g)
    # === Additional Options
    # <tt>:units</tt> - the units used
    def initialize(*args)
      if args.length == 4 and !args.last.is_a?(Hash)
        super(:name => args[0], :value => args[1], :units => args[2], :namespace => args.last)
      else
        super *args
      end
    end
  end

  class ReferenceAttribute < Attribute; end
  
  # LocationAttribute represents an Item's location
  class LocationAttribute < Attribute
    child_attribute :longitude
    child_attribute :latitude

  end

  class AuthorAttribute < Attribute
    child_attribute :email, :namespace => nil
    child_attribute :name,  :namespace => nil

    def initialize(*args)
      super(*args)
      @namespace = nil
    end

    def type_name; nil; end

  end
end
