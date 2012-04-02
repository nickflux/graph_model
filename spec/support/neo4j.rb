neography_options = 
GraphModel::Config.config({
  :protocol     => "http://",
  :server       => "localhost",
  :port         => 7475,
  :log_enabled  => true,
  :log_file     => "spec/support/log/neography.log",
  :cypher_pat   => "/ext/CypherPlugin/graphdb/execute_query"
})