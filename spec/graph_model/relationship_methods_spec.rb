require 'spec_helper'

describe GraphModel::RelationshipMethods do
    
  let(:author)      { Author.create(build(:author).attributes) }
  let(:author_new)  { Author.new }
  let(:entry)       { Entry.create(build(:entry).attributes) }
  
  describe "relationship_out" do
    
    context "persisted node" do
    
      it "have the expected defined methods" do
        author.respond_to?(:written).should be_true
        author.respond_to?(:get_written_relationship).should be_true
        author.respond_to?(:written_nodes).should be_true
        author.respond_to?(:add_written).should be_true
        author.respond_to?(:remove_written).should be_true
      end
    
      it "relationship method should be a NodeTraverser object" do
        author.written.class.should be(Neography::NodeTraverser)
      end
    
      it "have the expected defined convenience methods based on the [:only] option" do
        author.respond_to?(:entries).should be_true
        author.respond_to?(:entry).should be_true
        author.respond_to?(:entry_title).should be_true
        author.respond_to?(:entry_title=).should be_true
      end
      
    end
    
    context "new node" do
    
      it "have the expected defined methods" do
        author_new.respond_to?(:written).should be_true
        author_new.respond_to?(:get_written_relationship).should be_true
        author_new.respond_to?(:written_nodes).should be_true
        author_new.respond_to?(:add_written).should be_true
        author_new.respond_to?(:remove_written).should be_true
      end
    
      it "relationship method should be a NodeTraverser object" do
        author_new.written.class.should be(Neography::NodeTraverser)
      end
    
      it "have the expected defined convenience methods based on the [:only] option" do
        author_new.respond_to?(:entries).should be_true
        author_new.respond_to?(:entry).should be_true
        author_new.respond_to?(:entry_title).should be_true
        author_new.respond_to?(:entry_title=).should be_true
      end
      
      it "should return nil for convenience method", :focus do
        author_new.entry_title.should be_nil
      end
      
    end
    
  end
  
  describe "add_ relationship" do
    
    it "should create a relationship between two nodes" do
      author.add_written(entry)
      GraphModel.configuration.conn.execute_script("g.v(#{author.id}).out('written').id").first.should == entry.id
    end
    
    it "should raise an exception if try to create a relationship between two nodes of the wrong type" do
      author2 = Author.create(build(:author, :name => "Wrong Fellow").attributes)
      lambda do
        author.add_written(author2)
      end.should raise_exception(GraphModel::RelationshipError)
    end
    
    it "should raise an exception if try to create a relationship with an unsaved node" do
      entry2 = Entry.new(build(:entry).attributes)
      lambda do
        author.add_written(entry2)
      end.should raise_exception(GraphModel::RelationshipError, "Can't add a node to this relationship unless it has first been saved to the database.")
    end
    
  end
  
  describe "relationship _nodes" do
    
    it "returns the correct node from the relationship" do
      author.add_written(entry)
      author.written_nodes.should == [entry]
    end
    
  end
  
end