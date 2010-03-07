class Change
  include DataMapper::Resource

  property :change_hash, String, :key => true, :length => 32
  property :page, String, :length => 100
  property :changed_at, DateTime, :index => true
  property :line_changes, Integer
  property :editor, String
end
