module GraphModel

  class Config
    
    class << self
      
      def config(options)
        # this is not a good way to do this
        $neo = Neography::Rest.new(options)
      end
      
    end
    
  end


end
=begin
# neography connection
if Rails.env.development?
  NEO = Neography::Rest.new({ :protocol     => 'http://', 
                              :server       => 'localhost', 
                              :port         => 7474,
                              :log_enabled  => true,
                              :log_file     => 'log/neography.log',
                              :cypher_path  => '/ext/CypherPlugin/graphdb/execute_query'})
elsif Rails.env.test?
  NEO = Neography::Rest.new({ :protocol     => 'http://', 
                              :server       => 'localhost', 
                              :port         => 7475,
                              :log_enabled  => true,
                              :log_file     => 'log/neography.log',
                              :cypher_path  => '/ext/CypherPlugin/graphdb/execute_query'})
end
=end