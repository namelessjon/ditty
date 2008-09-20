class Ditty
  include DataMapper::Resource

  property :id, Serial
  property :title, String, :unique => true, :unique_index => true, :index => true, :nullable => false
  property :body, Text, :nullable => false
  property :created_at, DateTime
end
