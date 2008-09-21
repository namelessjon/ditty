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
    RedCloth.new(body).to_html.gsub(/([A-Z][a-z]+[A-Z][A-Za-z0-9]+)/) do |title|
      @ditty = Ditty.first(:title => title)
      if @ditty
        "<a class='existing' href='/ditty/#{@ditty.id}'>#{title}</a>"
      else
        "<a class='new_ditty' href='/ditty/new?title=#{title}'>#{title}</a>"
      end
    end
  end
end

get '/' do
  @ditties = Ditty.all
  haml :index
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
    <input type='text' name='ditty_title' size='60' value='#{(params['title']) ? params['title'] : ''}' /><br />
    <textarea name='ditty_body' cols='60' rows='10'></textarea>
  </form>
  </div>
  eos
end

get '/ditty/:id/edit' do
  @id = params['id']
  @ditty = Ditty.get(@id)
  throw :halt, [404, 'ditty not found'] unless @ditty
  body <<-eos
  <div class='ditty_edit' id='edit_ditty_#{@id}'>
  <h3>#{@ditty.title}</h3>
  <ul class='edit_links'>
    <li><a rel='cancel' href='/ditty/#{@id}'>cancel</a></li>
    <li><a rel='update' href='/ditty/#{@id}'>done</a></li>
    <li><a rel='destroy' href='/ditty/#{@id}'>delete</a></li>
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
  throw :halt, [400, 'Destory Failed']  unless @ditty.destroy
end

put '/ditty/:id' do
  @ditty = Ditty.get(params['id'])
  throw :halt, [404, 'ditty not found'] unless @ditty
  @ditty.title = params['title']
  @ditty.body = params['body']
  if !@ditty.dirty? || @ditty.save
    format_ditty(@ditty)
  else
    throw :halt, [400, @ditty.errors.full_messages.join("\n")]
  end
end

get '/ditty/:id' do
  @ditty = Ditty.get(params['id'])
  throw :halt, [404, 'ditty not found'] unless @ditty
  body format_ditty(@ditty)
end

post '/ditty' do
  @ditty = Ditty.new(:title => params['title'], :body => params['body'])
  if @ditty.save
    format_ditty(@ditty)
  else
    throw :halt, [400, @ditty.errors.full_messages.join("\n")]
  end
end


