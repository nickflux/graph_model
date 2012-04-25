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
    
    it "adds a related object - new object" do
      attrs = {:authors_attributes => {"0" => {:name => "Judy Newbie"}}, :title => "new title"}
      lambda do
        @entry = Entry.create(attrs)
      end.should change(Author, :count).by(1)
      Entry.find(@entry.id).authors.first.name.should == "Judy Newbie"
    end
    
    it "adds a related object with extra attributes" do
      attrs = {:authors_attributes => {"0" => {:name => "Judy Newbie", :age => 56}}, :title => "new title"}
      entry = Entry.create(attrs)
      Entry.find(entry.id).authors.first.name.should == "Judy Newbie"
      Entry.find(entry.id).authors.first.age.should == 56
    end
    
    it "adds multiple related objects - new object" do
      attrs = {:authors_attributes => {"0" => {:name => "Judy Newbie"}, "1" => {:name => "Johnny Bonny"}}, :title => "new title"}
      lambda do
        @entry = Entry.create(attrs)
      end.should change(Author, :count).by(2)
      Entry.find(@entry.id).authors.map(&:name).should include("Judy Newbie")
      Entry.find(@entry.id).authors.map(&:name).should include("Johnny Bonny")
    end
    
    it "adds a related object - existing object" do
      attrs = {:authors_attributes => {"0" => {:name => author.name}}, :title => "new title"}
      lambda do
        @entry = Entry.create(attrs)
      end.should_not change(Author, :count).by(1)
      Entry.find(@entry.id).authors.first.should == author
    end
    
    it "adds a related exiting object with extra attributes" do
      attrs = {:authors_attributes => {"0" => {:name => author.name, :age => 72}}, :title => "new title"}
      entry = Entry.create(attrs)
      Entry.find(entry.id).authors.first.name.should == author.name
      Entry.find(entry.id).authors.first.age.should == 72
    end
    
    it "adds multiple related objects - one new object, one existing object" do
      attrs = {:authors_attributes => {"0" => {:name => author.name}, "1" => {:name => "Johnny Bonny"}}, :title => "new title"}
      lambda do
        @entry = Entry.create(attrs)
      end.should change(Author, :count).by(1)
      Entry.find(@entry.id).authors.map(&:name).should include("Johnny Bonny")
      Entry.find(@entry.id).authors.map(&:name).should include(author.name)
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
    
    it "adds a related object - new object" do
      attrs = {:authors_attributes => {"0" => {:name => "Jane McNeverexisted"}}}
      lambda do
        entry.update(attrs)
      end.should change(Author, :count).by(1)
      Entry.find(entry.id).authors.first.should == Author.find_first_by_name("Jane McNeverexisted")
    end
    
    it "adds multiple related objects - new objects" do
      attrs = {:authors_attributes => {"0" => {:name => "Jane McNeverexisted"}, "1" => {:name => "Steven Klancefeather"}}}
      lambda do
        entry.update(attrs)
      end.should change(Author, :count).by(2)
      Entry.find(entry.id).authors.map(&:name).should include("Jane McNeverexisted")
      Entry.find(entry.id).authors.map(&:name).should include("Steven Klancefeather")
    end
    
    it "adds a related object - existing object" do
      attrs = {:authors_attributes => {"0" => {:name => author.name}}}
      lambda do
        entry.update(attrs)
      end.should_not change(Author, :count).by(1)
      Entry.find(entry.id).authors.first.should == author
    end
    
    it "adds multiple related objects - one new object, one existing" do
      attrs = {:authors_attributes => {"0" => {:name => "Jane McNeverexisted"}, "1" => {:name => author2.name}}}
      lambda do
        entry.update(attrs)
      end.should change(Author, :count).by(1)
      Entry.find(entry.id).authors.map(&:name).should include("Jane McNeverexisted")
      Entry.find(entry.id).authors.map(&:name).should include(author2.name)
    end
    
    it "remove a related object" do
      entry.add_written_by(author)
      entry.add_written_by(author2)
      entry.authors.count.should == 2
      attrs = {:authors_attributes => {"0" => {:name => author.name, :_destroy => 1}}}
      entry.update(attrs)
      Entry.find(entry.id).authors.count.should == 1
      Entry.find(entry.id).authors.map(&:name).should_not include(author.name)
    end
    
    it "don't remove a related object" do
      entry.add_written_by(author)
      entry.add_written_by(author2)
      entry.authors.count.should == 2
      attrs = {:authors_attributes => {"0" => {:name => author.name, :_destroy => 0}}}
      entry.update(attrs)
      Entry.find(entry.id).authors.count.should == 2
      Entry.find(entry.id).authors.map(&:name).should include(author.name)
    end
    
  end
  
  
end