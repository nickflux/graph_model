module GraphModel
    
  module RelationshipMethods
      
    RELATIONSHIP_TYPES  = {:relationship_out => :outgoing, :relationship_in => :incoming}.freeze
    
    module ClassMethods
      
      def setup_relationships
        class_attribute :relationships
        self.relationships  = []
      end
      
      
      [:relationship_out, :relationship_in].each do |relationship_method|
        define_method relationship_method do |name, options = {}|
      
          # Add Relationship instance methods
          RelationshipDefinition.new(RELATIONSHIP_TYPES[relationship_method], name, options).tap do |relationship_definition|
            define_relationship_methods(relationship_definition)
            relationships.push relationship_definition       
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
        
        # get the relationship object
        # for relationship :friends - get_friends_relationship(other_node)
        define_method "get_#{relationship_definition.name.to_s}_relationship" do |other_node|
          
          if relationship_definition.direction == :outgoing
            script  = "g.v(#{self.id}).outE.filter{it.label == '#{relationship_definition.name.to_s}'}.inV.filter{it.id == #{other_node.id}}.back(2).id"
          elsif relationship_definition.direction == :incoming
            script  = "g.v(#{self.id}).inE.filter{it.label == '#{relationship_definition.name.to_s}'}.outV.filter{it.id == #{other_node.id}}.back(2).id"
          end
          
          GraphModel.configuration.conn.execute_script(script).map do |rel_id| 
            Neography::Relationship.load(GraphModel.configuration.conn, rel_id)
          end.first
          
        end
      
        # see all the node objects at the other end of this relationship
        # for relationship :friends - friends_nodes
        define_method "#{relationship_definition.name.to_s}_nodes" do
          send(relationship_definition.name).map{|node| eval(node.object_type).find(node.neo_id) }
        end
      
        # add a new node object to the relationship
        # for relationship :friends - add_friends(other_node)
        define_method "add_#{relationship_definition.name.to_s}" do |other_node|
          
          if relationship_definition[:only] && !relationship_definition[:only].include?(other_node.class)
            msg = "cannot add a node of type #{other_node.class.to_s} to the #{relationship_definition.name.to_s} relationship. "
            msg +=  "Only #{relationship_definition[:only].map{|klass| klass.to_s}.join(' or ')} nodes allowed."
            raise GraphModel::RelationshipError, msg
          end
        
          raise GraphModel::RelationshipError, "Can't add a node to this relationship unless it has first been saved to the database." unless other_node.persisted?
        
          send(relationship_definition.name) << other_node.neo4j
        end
      
        # remove a node object from the relationship
        # for relationship :friends - remove_friends(other_node)
        define_method "remove_#{relationship_definition.name.to_s}" do |other_node|
        
          relationship  = send("get_#{relationship_definition.name.to_s}_relationship", other_node)
          if relationship
            relationship.del
            return true
          else
            raise GraphModel::RelationshipError, "This relationship does not exist"
          end
          
        end
      
        # alias methods for specified related models
        if relationship_definition[:only]
          relationship_definition[:only].each do |klass|
        
            # get all the node objects for this klass
            # for relationship :friends that are Doctor type - doctors
            define_method klass.to_s.tableize do
              send("#{relationship_definition.name.to_s}_nodes")
            end
          
            # get first node objects for this klass
            # for relationship :friends that are Doctor type - doctor
            define_method klass.to_s.underscore do
              send(klass.to_s.tableize).first
            end
          
            # convenience methods for creating related form inputs
            klass.attributes.each_key do |attribute_name|
            
              # read related attribute
              define_method "#{klass.to_s.underscore}_#{attribute_name}" do
                send(klass.to_s.underscore).send(attribute_name.to_sym)
              end
            
              # write related attribute
              define_method "#{klass.to_s.underscore}_#{attribute_name}=" do |attribute_value|
                puts "WRITING #{klass.to_s.underscore}_#{attribute_name} with #{attribute_value}"
              end
            
            end
        
          end
        end

      end
      
    end
    
    module InstanceMethods
      
      def relationships
        "instance relationships"
      end
      
      # the assumption here is that all relationships are one-to-one
      # as far as Neography / Neo4J is concerned this needn't be the case, but it's a good starting point
      def manage_relationships
        self.class.relationships.each do |relationship_definition|
          manage_relationship(relationship_definition)
        end
      end
      
      # manage a specific relationship
      def manage_relationship(relationship_definition)
        relationship_definition[:only].each do |related_klass|
          # relationship keys are the fields to find a related object on
          # they are the intersection of the relation object fields and the attributes sent to make the relationship
          realtionship_keys = related_klass.attributes.keys.map{|a| "#{related_klass.to_s.underscore}_#{a}"} & related_attributes.keys

          if realtionship_keys.size > 0
            # we are attempting to make a relationship
            # currently this is only done on the first relationship key
            # we are assuming that only is being sent, but again this need not be the case
            # in future we could use `realtionship_keys.each do |realtionship_key|; end`
            realtionship_key  = realtionship_keys.first
            
            # update `relationship_definition.name` on `realtionship_key`
            
            related_attribute_key   = realtionship_key.gsub("#{related_klass.to_s.underscore}_", "")
            new_related_object      = related_klass.send("find_first_by_#{related_attribute_key}", related_attributes[realtionship_key])
      
            # if this related object does not exist yet create it
            new_related_object  ||= related_klass.create(related_attribute_key => related_attributes[realtionship_key])
            
            make_relationship(relationship_definition, new_related_object)
 
          else
            # nothing to do for `relationship_definition.name`
          end
          
        end
          
      end
      
      def make_relationship(relationship_definition, new_related_object)
        
        # does the relationship exist yet?
        if send("#{relationship_definition.name.to_s}_nodes").count > 0
          # if the relationship already with the new_related_object, do nothing
          # otherwise delete the rlationship and add the new_related_object
          current_related_object = send("#{relationship_definition.name.to_s}_nodes").first
          unless current_related_object == new_related_object
            send("remove_#{relationship_definition.name.to_s}", current_related_object)
            send("add_#{relationship_definition.name.to_s}", new_related_object)
          end
        else
          # a relationship named 'relationship_definition.name' does not exist - create it
          send("add_#{relationship_definition.name.to_s}", new_related_object)
        end
        
      end
      
    end
          
  end
    
end