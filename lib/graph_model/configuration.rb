module GraphModel

  class Configuration
  
    
    def connection(connection_options)
      @connection ||= begin
        Neography::Rest.new({
        :protocol     => "http://",
        :server       => "localhost",
        :port         => 7474,
        :log_enabled  => true,
        :log_file     => "spec/support/log/neography.log",
        :cypher_pat   => "/ext/CypherPlugin/graphdb/execute_query"
        }.merge(connection_options))
      end

    end
    
    def conn
      @connection
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