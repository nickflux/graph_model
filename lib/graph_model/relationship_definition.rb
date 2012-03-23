module GraphModel
  # Represents an attribute for reflection
  #
  # @example Usage
  #   RelationshipDefinition.new(:amount)
  #
  class RelationshipDefinition
    
    attr_reader :direction, :name
    
    # Read an attribute option
    #
    # @example
    #   attribute_definition[:type]
    #
    # @param [Symbol] key The option key
    #
    def [](key)
      @options[key]
    end

    # Creates a new RelationshipDefinition
    #
    # @example Create an attribute defintion
    #   RelationshipDefinition.new(:amount)
    #
    # @param [Symbol, String, #to_sym] name attribute name
    #
    # @return [GraphModel::RelationshipDefinition]
    #
    def initialize(direction, name, options={})
      raise TypeError, "can't convert #{name.class} into Symbol" unless name.respond_to? :to_sym
      @direction  = direction.to_sym
      @name       = name.to_sym
      @options    = options
    end

    # The attribute name
    #
    # @return [String] the attribute name
    #
    def to_s
      name.to_s
    end

    # The attribute name
    #
    # @return [Symbol] the attribute name
    #
    def to_sym
      name
    end

    protected

    # The attribute options
    attr_reader :options
  end
end
