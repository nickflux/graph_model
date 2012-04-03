require 'spec_helper'

describe GraphModel::Node do
  
  describe "create" do
    
    let(:author)  { Author.create(build(:author).attributes) }
    
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
      attrs     = {:title => 'for reals', :no_attr => "don't do it"}
      new_entry = Entry.create(attrs)
      neo4j_obj = Entry.find(new_entry.id).neo4j
      neo4j_obj.respond_to?(:no_attr).should be_false
    end
    
    it "adds a related object using a related field finder - new object" do
      attrs = {:author_name => "Judy Newbie", :title => "new title"}
      lambda do
        @entry = Entry.create(attrs)
      end.should change(Author, :count).by(1)
      Entry.find(@entry.id).author.name.should == "Judy Newbie"
    end
    
    it "adds a related object using a related field finder - existing object" do
      attrs = {:author_name => author.name, :title => "new title"}
      lambda do
        @entry = Entry.create(attrs)
      end.should_not change(Author, :count).by(1)
      Entry.find(@entry.id).author.should == author
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
    let(:author)  { Author.create(build(:author).attributes) }
    let(:author2) { Author.create(build(:author, :name => "Bert Jorkel").attributes) }
    
    it "updates a node with new values" do
      attrs = {:title => "new title"}
      entry.update(attrs)
      Entry.find(entry.id).title.should == attrs["title"]      
    end
    
    it "does not add an attribute that is not in the model description" do
      attrs = {:no_attr => "don't do it"}
      entry.update(attrs)
      neo4j_obj = Entry.find(entry.id).neo4j
      neo4j_obj.respond_to?(:no_attr).should be_false
    end
    
    it "adds a related object using a related field finder - new object" do
      attrs = {:author_name => "Jane McNeverexisted"}
      lambda do
        entry.update(attrs)
      end.should change(Author, :count).by(1)
      Entry.find(entry.id).author.should == Author.find_first_by_name("Jane McNeverexisted")
    end
    
    it "adds a related object using a related field finder - existing object" do
      attrs = {:author_name => author.name}
      lambda do
        entry.update(attrs)
      end.should_not change(Author, :count).by(1)
      Entry.find(entry.id).author.should == author
    end
    
    it "replaces a related object with another one" do
      entry.add_written_by(author)
      attrs = {:author_name => author2.name}
      entry.update(attrs)
      Entry.find(entry.id).author.should == author2
      Entry.find(entry.id).written_by_nodes.size.should == 1
    end
    
  end
  
  
end