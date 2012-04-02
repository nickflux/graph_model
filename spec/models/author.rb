class Author
  
  include GraphModel::Node
  
  attribute  :name, type: String
  validates :name, :presence => true
  
  relationship_out :written, :only => [Entry]
    
end