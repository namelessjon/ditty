class Ditty
  include DataMapper::Resource

  property :id, Serial
  property :title, String,  :unique => true, :required => true
  property :body, Text,     :required => true, :messages => { :presence => 'Ditty needs content' }
  property :created_at, DateTime
end
