require 'rubygems'
require 'sinatra'
require 'dm-validations'
require 'dm-core'
require 'json'
require 'redcloth'


configure do
  DataMapper::Logger.new(STDERR, :debug)
  DataMapper.setup(:default, "sqlite3:songbook.db")

  require 'models'
#  DataMapper.auto_migrate!
end

helpers do
  def format_ditty(ditty)
    string = <<-eos
    <div class='ditty' id='ditty_#{ditty.id}'>
      <h3>#{ditty.title}</h3>
      <ul class='ditty_control'>
        <li><a rel='close' href='/ditty/#{ditty.id}'>close</a></li>
        <li><a rel='edit' href='/ditty/#{ditty.id}/edit'>edit</a></li>
      </ul>
    #{linkify_text(ditty.body)}
    <ul class='tags'>
    <li>tags would be here</li>
    </ul>
    </div>
    eos
  end

  def linkify_text(body)
    RedCloth.new(body).to_html
  end
end

get '/' do
  @ditties = Ditty.all
  haml :index
end

get '/ditty/:id/edit' do
  @id = params['id']
  @ditty = Ditty.get(@id)
  throw :halt, [404, 'ditty not found'] unless @ditty
  body <<-eos
  <div class='ditty_edit' id='edit_ditty_#{@id}'>
  <h2>#{@ditty.title}</h2>
  <ul class='edit_links'>
    <li><a href='/ditty/#{@id}' rel='cancel'>cancel</a></li>
    <li><a href='/ditty/#{@id}' rel='update'>done</a></li>
    <li><a href='/ditty/#{@id}' rel='destroy'>delete</a></li>
  </ul>
  <form action='ditty/#{@id}' id='ditty_form_#{@id}'>
    <input type='text' name='ditty_title' size='60' value='#{@ditty.title}' /><br />
    <textarea name='ditty_body' cols='60' rows='10'>#{@ditty.body}</textarea>
  </form>
  </div>
  eos
end

delete '/ditty/:id' do
  @ditty = Ditty.get(params['id'])
  throw :halt, [404, 'ditty not found'] unless @ditty
  throw :halt, [403, 'Destory Failed']  unless @ditty.destroy
end

put '/ditty/:id' do
  @ditty = Ditty.get(params['id'])
  throw :halt, [404, 'ditty not found'] unless @ditty
  @ditty.title = params['title']
  @ditty.body = params['body']
  if !@ditty.dirty? || @ditty.save
    format_ditty(@ditty)
  else
    throw :halt, [403, @ditty.errors.full_messages.join("\n")]
  end
end

post '/ditty' do
  @ditty = Ditty.new(:title => params['title'], :body => params['body'])
  if @ditty.save
    format_ditty(@ditty)
  else
    throw :halt, [403, @ditty.errors.full_messages.join("\n")]
  end
end


get '/ditty/new' do
  body <<-eos
  <div class='ditty_edit'>
  <h2>New Ditty</h2>
  <ul class='edit_links'>
    <li><a href='/ditty' rel='cancel'>cancel</a></li>
    <li><a href='/ditty' rel='create'>done</a></li>
  </ul>
  <form action='ditty' class='new_ditty_form'>
    <input type='text' name='ditty_title' size='60' value='' /><br />
    <textarea name='ditty_body' cols='60' rows='10'></textarea>
  </form>
  </div>
  eos
end
