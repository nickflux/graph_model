SPEC_ROOT = File.expand_path('..', __FILE__)
require 'graph_model'
require 'factory_girl'
require 'log_buddy'
require "#{SPEC_ROOT}/factories.rb"
Dir["#{SPEC_ROOT}/support/**/*.rb"].each { |file| require file }

# autoload models
Dir["spec/models/*.rb"].each do |file|
  autoload File.basename(file, ".rb").titleize.to_sym, "models/#{File.basename(file, ".rb")}"
end


# start db with /usr/local/neo4j-test/bin/neo4j start

RSpec.configure do |config|
  
  require 'rspec/expectations'
  config.include RSpec::Matchers
  
  config.include FactoryGirl::Syntax::Methods
  
  # only run specs tagged with focus id any are tagged
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  
  config.before(:each) do
    GraphModel.configuration.conn.clean_database("yes_i_really_want_to_clean_the_database")
  end

  config.after(:all) do
    GraphModel.configuration.conn.clean_database("yes_i_really_want_to_clean_the_database")
  end
  
end