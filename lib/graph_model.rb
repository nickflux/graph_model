require 'neography'
require 'active_attr'
require 'graph_model/version'
require 'graph_model/configuration'
require 'graph_model/node'
require 'graph_model/relationship_definition'
require 'graph_model/relationship_methods'

module GraphModel
  

  def self.configuration
    @configuration ||= GraphModel::Configuration.new
  end

  # Yields the global configuration to a block.
  # @yield [Configuration] global configuration
  #
  # @example
  #     GraphModel.configure do |config|
  #       config.connection 'documentation'
  #     end
  def self.configure
    yield configuration if block_given?
  end
  
  
end
