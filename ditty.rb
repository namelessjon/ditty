require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'json'
require 'redcloth'
require 'haml'


configure do
  DataMapper::Logger.new(STDERR, :debug) if development?
  DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3:songbook.db")

  require 'models'
#  DataMapper.auto_migrate!
end

helpers do
  def format_ditty(ditty)
    string = <<-eos
    <div class='ditty' id='#{ditty.title}'>
      <h3>#{ditty.title}</h3>
      <ul class='ditty_control'>
        <li><a rel='close' href='/#{ditty.title}'>close</a></li>
        <li><a rel='edit' href='/#{ditty.title}/edit'>edit</a></li>
      </ul>
    <div class='body'>
    #{linkify_text(ditty.body)}
    </div>
    <ul class='tags'>
    <li>tags would be here</li>
    </ul>
    </div>
    eos
  end

  def linkify_text(body)
    RedCloth.new(body).to_html.gsub(/([A-Z][a-z]+[A-Z][A-Za-z0-9]+)/) do |title|
      ditty2link(title)
    end
  end

  def ditty2link(title)
    ditty = Ditty.first(:title => title)
    if ditty
      "<a class='existing' href='/#{title}' title='#{title}'>#{title}</a>"
    else
      "<a class='new_ditty' href='/new?title=#{title}' title='#{title}'>#{title}</a>"
    end
  end

  def make_hot_ditty_list(body)
    body.split("\n").map {|t| "<li>#{ditty2link(t.strip)}</li>" }
  end
end

get '/' do
  @hot_ditties = Ditty.first(:title => 'HotDitties')
  if @hot_ditties
    # if we have a hot ditties tiddler, split it out ...
    ditty_list = @hot_ditties.body.split("\n").map {|t| t.strip }
    # ... and find those ditties
    @ditties = Ditty.all(:title.in => ditty_list)
    @hot_ditty_list = make_hot_ditty_list(@hot_ditties.body)
  else
    # just display the first 10
    @ditties = Ditty.all(:limit => 10, :order => [:created_at.desc])
    @hot_ditty_list = ""
  end
  haml :index
end

get '/new' do
  haml :new
end

get '/:id/edit' do
  @id = params['id']
  @ditty = Ditty.first(:title => @id)
  throw :halt, [404, 'ditty not found'] unless @ditty
  haml :edit
end

delete '/:id' do
  @ditty = Ditty.first(:title => params['id'])
  throw :halt, [404, 'ditty not found'] unless @ditty
  throw :halt, [400, 'Destroy Failed']  unless @ditty.destroy
  params['id']
end

put '/:id' do
  @ditty = Ditty.first(:title => params['id'])
  throw :halt, [404, 'ditty not found'] unless @ditty
  @ditty.title = params['title'] if params['title']
  @ditty.body = params['body'] if params['body']
  if @ditty.save
    format_ditty(@ditty)
  else
    throw :halt, [400, @ditty.errors.full_messages.join("\n")]
  end
end

get '/:id' do
  @ditty = Ditty.first(:title => params['id'])
  throw :halt, [404, 'ditty not found'] unless @ditty
  body format_ditty(@ditty)
end

post '/' do
  @ditty = Ditty.new(:title => params['title'], :body => params['body'])
  if @ditty.save
    format_ditty(@ditty)
  else
    throw :halt, [400, @ditty.errors.full_messages.join("\n")]
  end
end
