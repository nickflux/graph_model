module GraphModel
    
  module RelationshipMethods
      
    RELATIONSHIP_TYPES  = {:relationship_out => :outgoing, :relationship_in => :incoming}.freeze
    
    [:relationship_out, :relationship_in].each do |relationship_method|
      define_method relationship_method do |name, options = {}|
      
        # Add Relationship instance methods
        RelationshipDefinition.new(RELATIONSHIP_TYPES[relationship_method], name, options).tap do |relationship_definition|
          define_relationship_methods(relationship_definition)
        end
      
      end
    end    
    
    def define_relationship_methods(relationship_definition)
      
      # see the relationship object
      # for relationship :friends - friends
      define_method relationship_definition.name do
        direction = relationship_definition.direction.to_s
        name      = relationship_definition.name
        eval("self.neo4j.#{direction}(name)")
      end
      
      # see all the node objects at the other end of this relationship
      # for relationship :friends - friends_nodes
      define_method "#{relationship_definition.name.to_s}_nodes" do
        send(relationship_definition.name).map{|node| eval(node.object_type).find(node.neo_id) }
      end
      
      # add a new node object to the outgoing relationship
      # for relationship :friends - add_friends
      define_method "add_#{relationship_definition.name.to_s}" do |other_node|
        
        if relationship_definition[:only] && !relationship_definition[:only].include?(other_node.class)
          msg = "cannot add a node of type #{other_node.class.to_s} to the #{relationship_definition.name.to_s} relationship. "
          msg +=  "Only nodes of type #{relationship_definition[:only].map{|klass| klass.to_s}.join(' or ')} allowed."
          raise GraphModel::RelationshipError, msg
        end
        
        raise GraphModel::RelationshipError, "Can't add a node to this relationship unless it has first been saved to the database." unless other_node.persisted?
        
        send(relationship_definition.name) << other_node.neo4j
      end

    end
          
  end
    
end