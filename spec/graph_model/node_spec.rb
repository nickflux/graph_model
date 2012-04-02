require 'spec_helper'

describe GraphModel::Node, :focus do
  
  describe "create" do
    
    it "should create a new object in the database" do
      
      lambda do
        Entry.create(:title => "new title")
      end.should change(Entry, :count).by(1)
      
    end
    
    it "should not create a new object if validations don't allow" do
      
      lambda do
        Entry.create(:title => nil)
      end.should_not change(Entry, :count).by(1)
      
    end
    
    it "does not add an attribute that is not in the model description" do
      pending
    end
    
  end
  
  context "finders" do
    
    let(:entry)   { Entry.create(build(:entry).attributes) }
    let(:author)  { Author.create(build(:author).attributes) }
    
    describe "find" do
      
      it "finds an object with its ID" do
        Entry.find(entry.id).title.should == entry.title
      end
      
      it "does not find an object with its ID if it is the wrong type" do
        Entry.find(author.id).should be_false
      end
      
    end
    
  end
  
  describe "update" do
    
    let(:entry)   { Entry.create(build(:entry, :title => "old title").attributes) }
    
    it "updates a node with new values" do
      attrs = {:title => "new title"}
      entry.update(attrs)
      Entry.find(entry.id).title.should == attrs[:title]      
    end
    
    it "does not add an attribute that is not in the model description" do
      pending
    end
    
  end
  
  
end