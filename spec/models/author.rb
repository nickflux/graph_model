class Author
  
  include GraphModel::Node
  
  attribute  :name, type: String
  attribute  :age, type: Integer
  validates :name, :presence => true
  
  relationship_out :written, :with => Entry, :on_field => :title
    
end