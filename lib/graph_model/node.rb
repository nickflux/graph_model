module GraphModel
  
  class NodeError < StandardError; end
  class RelationshipError < StandardError; end
  
  module Node
    
    FIXED_ATTRIBUTES  = [:id, :object_type].freeze
    
    module ClassMethods
      
      def setup_graph_model_node(options = {})
        options             = default_model_options.merge(options)
        class_attribute :model_options
        self.model_options  = options 
        
        attr_accessor :neo4j
    
        attribute :id, type: Integer
        attribute :object_type, type: String

        attribute  :updated_at_i, type: Integer
        attribute  :created_at_i, type: Integer
        
      end
      
      def default_model_options
        {}
      end
      
      def build_object_from_neo4j(neo4j_object)
        
          new_obj               = new
          new_obj.neo4j         = neo4j_object
        
          # assign attributes
          attributes_to_assign  = attributes.keys
          attributes_to_assign.each do |attribute|
            new_obj[attribute.to_sym] = new_obj.neo4j[attribute.to_sym]
          end
        
          new_obj.id          = new_obj.neo4j.neo_id.to_i
        
          return new_obj
          
        end
      
      
        def create(attributes = {})
        
          new_obj = new(attributes)
        
          # check for invalid attributes
          if new_obj.valid?
            attributes.merge!({object_type: new_obj.class.to_s, created_at_i: Time.now.to_i, updated_at_i: Time.now.to_i})
            new_obj = build_object_from_neo4j Neography::Node.create($neo, attributes)
          end
          
          return new_obj
        end
      
        def find(neo_id)
          build_object_from_neo4j Neography::Node.load($neo, neo_id)
        end
      
        def all
          $neo.execute_script("g.V.filter{it.object_type == '#{self.new.class.to_s}'}.id").map do |neo_id|
            build_object_from_neo4j Neography::Node.load($neo, neo_id)
          end
        end
      
        def first
          all.first
        end
      
        def last
          all.last
        end
      
        # SEARCHING
        # $neo.execute_script("g.V.filter{it.name == 'Olympics'}.id").first
        # find all
        # g.V
        # g.V.filter{it.object_type == 'Event'}
      
    end
  
    module InstanceMethods
    
      def save
      
      end
    
      def update(new_attributes = {})
      
        raise GraphModel::NodeError, "object has no Neography::Node" unless neo4j
        
        new_attributes.merge!({updated_at_i: Time.now.to_i})
        self.attributes = attributes.merge(new_attributes)
      
        # check for invalid attributes
        if valid?
          $neo.set_node_properties(neo4j, new_attributes)
          true
        else
          false
        end
        
      end
    
      def destroy
        neo4j.del
        nil
      end
    
      def persisted?
        !id.nil?
      end
    
      def created_at
        DateTime.strptime(created_at_i.to_s, "%s")
      end
    
      def updated_at
        DateTime.strptime(updated_at_i.to_s, "%s")
      end
    
      # create relationship
      # prediction.neo4j.outgoing(:predicted_about) << event.neo4j
      # event.neo4j.incoming(:predicted_about).map(&:prediction)
    
      # prediction.neo4j.outgoing(:predicted_by) << pundit.neo4j
      # event.neo4j.incoming(:predicted_about).outgoing(:predicted_by).map(&:name)
    
      # find pundits who predicted an event:
      # $neo.execute_script("g.v(#{event.id}).in.out('predicted_by')")
    
      # find pundits who predicted the same event
      # g.v(557).as('x').in.out('predicted_about').in.out('predicted_by').filter{it.id != 557}.map
      # or 
      # v = g.v(557); v.in.out('predicted_about').in.out('predicted_by').filter{it != v}.map
      
      
    end
  
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.extend         GraphModel::RelationshipMethods
      receiver.send :include, ::ActiveAttr::Model
      receiver.send :include, InstanceMethods
      receiver.send :setup_graph_model_node
    end
    
  end
    
end