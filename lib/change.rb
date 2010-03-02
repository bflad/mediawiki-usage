class Change
  include DataMapper::Resource

  property :change_hash, String, :key => true
  property :topic, String
  property :changed_at, DateTime
  property :line_changes, Integer
  property :editor, String  
end
