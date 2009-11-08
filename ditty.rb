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
      @ditty = Ditty.first(:title => title)
      if @ditty
        "<a class='existing' href='/#{title}'>#{title}</a>"
      else
        "<a class='new_ditty' href='/new?title=#{title}'>#{title}</a>"
      end
    end
  end
end

get '/' do
  @hot_ditties = Ditty.first(:title => 'HotDitties')
  if @hot_ditties
    # if we have a hot ditties tiddler, split it out ...
    ditty_list = @hot_ditties.body.split("\n").map {|t| t.strip }
    # ... and find those ditties
    @ditties = Ditty.all(:title.in => ditty_list)
    haml :index
  else
  end
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
  throw :halt, [400, 'Destory Failed']  unless @ditty.destroy
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

use_in_file_templates!

__END__

@@ index
!!! XML
!!!
%html{:xmlns => "http://www.w3.org/1999/xhtml", 'xml:lang' => "en", :lang => "en"}
  %head
    %title Ditty - A non-linear web notebook
    %script{:type => 'text/javascript', :src => 'jquery.js'}
    %script{:type => 'text/javascript', :src => 'jquery.livequery.min.js'}
    %script{:type => 'text/javascript', :src => 'jquery.form.js'}
    %script{:type => 'text/javascript', :src => 'ditty.js'}
  %body
    %h1 Ditty
    %h2 A non-linear web notebook
    #content
      #menubar Menu goes here!
      #ditties
        - @ditties.each do |ditty|
          =format_ditty(ditty)
      #sidebar
        %a.new_ditty{:href => '/ditty/new'} New Ditty
        %a.close_all{:href => '#'} Close All

@@ edit
.ditty_edit{:id => "edit_#{@ditty.title}"}
  %h3= @ditty.title
  %ul.edit_links
    %li
      %a{:rel => 'cancel', :href => "/#{@ditty.title}"} cancel
    %li
      %a{:rel => 'update', :href => "/#{@ditty.title}"} done
    %li
      %a{:rel => 'destroy', :href => "/#{@ditty.title}"} delete
  %form{:action => "/#{@ditty.title}", :id => "#{@ditty.title}_form"}
    %input{:type => "text", :name => "ditty_title", :size => 60, :value => @ditty.title}
    %br
    %text_area{:name => 'ditty_body', :cols => 60, :rows => 10}= @ditty.body

@@ new
.ditty_edit
  %h3= (params['title']) ? "#{params['title']} (New)" : "New Ditty"
  %ul.edit_links
    %li
      %a{:rel => 'cancel', :href => "/"} cancel
    %li
      %a{:rel => 'create', :href => "/"} done
  %form.edit_links{:action => '/'}
    %input{:type => "text", :name => "ditty_title", :size => 60, :value => "{(params['title']) ? params['title'] : ''}"}
    %br
    %text_area{:name => 'ditty_body', :cols => 60, :rows => 10}

