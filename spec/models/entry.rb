class Entry
  
  include GraphModel::Node
  
  attribute  :title, type: String
  validates :title, :presence => true
  
  relationship_in :written_by, :with => Author, :on_field => :name
  
end