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
        
        setup_relationships
        
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
    
    
      def create(new_attributes = {})
        
        new_attributes  = allowed_attributes(new_attributes)
        new_obj         = new(attributes)
      
        # check for invalid attributes
        if new_obj.valid?
          new_attributes.merge!({object_type: new_obj.class.to_s, created_at_i: Time.now.to_i, updated_at_i: Time.now.to_i})
          new_obj = build_object_from_neo4j Neography::Node.create($neo, new_attributes)
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
      
      def method_missing(meth, *args, &block)
        if meth.to_s =~ /^find_by_(.+)$/
          run_find_by_method($1, *args, &block)
        elsif meth.to_s =~ /^find_first_by_(.+)$/
          run_find_first_by_method($1, *args, &block)
        else
          super # You *must* call super if you don't handle the
                # method, otherwise you'll mess up Ruby's method
                # lookup.
        end
      end

      def run_find_by_method(attrs, *args, &block)
        # Make an array of attribute names
        attrs = attrs.split('_and_')

        # #transpose will zip the two arrays together like so:
        #   [[:a, :b, :c], [1, 2, 3]].transpose
        #   # => [[:a, 1], [:b, 2], [:c, 3]]
        attrs_with_args = [attrs, args].transpose

        # Hash[] will take the passed associative array and turn it
        # into a hash like so:
        #   Hash[[[:a, 2], [:b, 4]]] # => { :a => 2, :b => 4 }
        conditions = Hash[attrs_with_args]

        build_query = ["it.object_type == '#{self.new.class.to_s}'"]
        
        conditions.each do |attr, value|
          build_query.push "it.#{attr} == '#{value}'"
        end
        query = build_query.join(" && ")
        
        $neo.execute_script("g.V.filter{#{query}}.id").map do |neo_id|
          build_object_from_neo4j Neography::Node.load($neo, neo_id)
        end
        
      end
      
      def run_find_first_by_method(attrs, *args, &block)
        run_find_by_method(attrs, *args, &block).first
      end
      
      
      def allowed_attributes(attributes_hash)
        allowed_attributes  = attributes_hash.clone
        allowed_attributes.delete_if {|key, value| !attributes.has_key?(key) } 
      end

      def related_attributes(attributes_hash)
        related_attributes  = attributes_hash.clone
        related_attributes.delete_if {|key, value| attributes.has_key?(key) } 
      end
      
    end
  
    module InstanceMethods
      
      def initialize(*args)
        super(*args)
      end
    
      def save
      
      end
    
      def update(new_attributes = {})
      
        raise GraphModel::NodeError, "object has no Neography::Node" unless neo4j
        
        related_attributes  = self.class.related_attributes(new_attributes)
        new_attributes      = self.class.allowed_attributes(new_attributes)
        
        new_attributes.merge!({updated_at_i: Time.now.to_i})
        self.attributes = attributes.merge(new_attributes)
      
        # check for invalid attributes
        if valid?
          $neo.set_node_properties(neo4j, new_attributes)
          
          # relationship creation
          self.class.relationships.each do |relationship_definition|
            relationship_definition[:only].each do |related_klass|
              realtionship_keys = related_klass.attributes.keys.map{|a| "#{related_klass.to_s.underscore}_#{a}"} & related_attributes.keys
              # TODO: start here
              if realtionship_keys.size > 0
                realtionship_keys.each do |realtionship_key|
                  related_attribute_key   = realtionship_key.gsub("#{related_klass.to_s.underscore}_", "")
                  puts "update #{relationship_definition.name} on #{realtionship_key}"
                  current_related_object  = self.send(related_klass.to_s.underscore)
                  new_related_object      = related_klass.send("find_first_by_#{related_attribute_key}", related_attributes[realtionship_key])
                  
                  # if this related object does not exist yet create it
                  new_related_object  ||= related_klass.create(related_attribute_key => related_attributes[realtionship_key])
                  
                end
              else
                #puts "nothing to do for #{relationship_definition.name}"
              end
            end
          end
          
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
      receiver.extend         GraphModel::RelationshipMethods::ClassMethods
      receiver.send :include, ::ActiveAttr::Model
      receiver.send :include, InstanceMethods
      receiver.send :include, GraphModel::RelationshipMethods::InstanceMethods
      receiver.send :setup_graph_model_node
    end
    
  end
    
end