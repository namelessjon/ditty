require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'rspec_hpricot_matchers'
require 'rack/test'

module RackTestMethods
  def app
    Sinatra::Application.new
  end
end


Spec::Runner.configure do |config|
  config.include RspecHpricotMatchers
  config.include Rack::Test::Methods
  config.include RackTestMethods
end

# setup database enviroment and require ditty.
File.unlink('test.log') if File.exists?('test.log')
DataMapper::Logger.new('test.log', :debug)
ENV['DATABASE_URL'] = 'sqlite3::memory:'
require 'ditty'

describe 'Ditty Application' do
  before(:all) do
    DataMapper.auto_migrate!
  end

  describe 'GET /' do
    describe 'with a HotDitties ditty' do
      before(:all) do
        post '/', :title => 'AnAwesomeDitty', :body => 'See how awesome it is?'
        post '/', :title => 'PlainDitty', :body => 'Nothing to see here, move along'
        post '/', :title => 'ALessThanAwesomeDitty', :body => 'See how un-awesome it is?'
        post '/', :title => 'HotDitties', :body => 'AnAwesomeDitty'
        get '/'
        @response = last_response
        @body     = last_response.body.to_s
      end

      after(:all) do
        DataMapper.auto_migrate!
      end


      it "shows successfully" do
        @response.should be_ok
      end

      it "has a ditty mentioned on the hot ditty page" do
        @body.should have_tag('div.ditty#AnAwesomeDitty')
      end

      it "doesn't have a ditty which isn't mentioned" do
        @body.should_not have_tag('div.ditty#ALessThanAwesomeDitty')
      end

      it "shows multiple ditties when they're on the list" do
        put '/HotDitties', :body => "AnAwesomeDitty\nPlainDitty"
        get '/'
        last_response.body.should have_tag('div.ditty#PlainDitty')
        last_response.body.should have_tag('div.ditty#AnAwesomeDitty')
      end
    end
  end

  describe 'POST /' do
    before(:all) do
      post '/', :title => 'AnAwesomeDitty', :body => 'See how awesome it is?'
      @response = last_response
      @body     = last_response.body.to_s
    end

    after(:all) do
      DataMapper.auto_migrate!
    end


    it 'creates new ditties by posting to /' do
      @response.should be_ok
    end

    it 'returns a ditty' do
      @body.should have_tag('div.ditty')
      @body.should have_tag('div.ditty div.body')
    end

    it 'returns the new ditty' do
      @body.should have_tag('div.ditty') do |ditty|
        ditty.should have_tag('h3', 'AnAwesomeDitty')
      end
    end

    it 'returns the ditty with an id' do
      @body.should have_tag('div#AnAwesomeDitty')
    end

    it 'has a edit link' do
      @body.should have_tag("a[@rel='edit' @href='/AnAwesomeDitty/edit']")
    end

    it 'has a close link' do
      @body.should have_tag("a[@rel='close' @href='/AnAwesomeDitty']")
    end

    it 'responds with 400 if there are validation issues' do
      post '/', :title => 'AnAwesomeDitty'
      last_response.status.should eql(400)
    end

    it 'returns the validation issues' do
      post '/', :title => 'AnAwesomeDitty'
      last_response.body.to_s.should match(/Ditty needs content/)
    end

    it 'duplicate titles are not allowed' do
      post '/', :title => 'AnAwesomeDitty', :body => 'See how awesome it is?'
      last_response.status.should eql(400)
    end
  end


  describe 'GET /new' do
    before(:all) do
      get '/new'
      @response = last_response
      @body     = last_response.body.to_s
    end


    it 'has an action to supply a new ditty form' do
      @response.should be_ok
    end

    it 'returns a new ditty form' do
      @body.should have_tag('div.ditty_edit') do |div|
        div.should have_tag('h3', 'New Ditty')
      end
    end

    it 'it returns a new ditty form with an actual form!' do
      @body.should have_tag('div.ditty_edit form[@action="/"]')
    end

    it 'has an input field for a ditty title' do
      @body.should have_tag('form[@action="/"] input[@name="ditty_title"]')
    end

    it 'has an input field for a ditty title which is empty when no param is passed' do
      @body.should have_tag('form[@action="/"] input[@name="ditty_title" @value=""]')
    end

    it 'fills in the title when the param is passed' do
      get '/new?title=YayDitty'
      last_response.body.should have_tag('form[@action="/"] input[@name="ditty_title" @value="YayDitty"]')
    end
  end


  describe 'individual ditties' do
    before(:all) do
      Ditty.create(:title => 'AnAwesomeDitty', :body => 'See how awesome it is?')
      Ditty.create(:title => 'LinkTestingDitty', :body => 'Have you seen AnAwesomeDitty ?')
    end

    after(:all) do
      DataMapper.auto_migrate!
    end


    describe 'GET /AnAwesomeDitty' do
      before(:all) do
        get '/AnAwesomeDitty'
        @response = last_response
        @body     = last_response.body.to_s
      end


      it 'responds successfully if the ditty exists' do
        @response.should be_ok
      end

      it 'returns a ditty' do
        @body.should have_tag('div.ditty')
        @body.should have_tag('div.ditty div.body')
      end

      it 'returns the ditty' do
        @body.should have_tag('div.ditty') do |ditty|
          ditty.should have_tag('h3', 'AnAwesomeDitty')
          ditty.should have_tag('div.body') do |body|
            body.inner_html.should match(/See how awesome it is\?/)
          end
        end
      end

      it 'returns a ditty with an id' do
        @body.should have_tag('div#AnAwesomeDitty')
      end

      it 'has a edit link' do
        @body.should have_tag("a[@rel='edit' @href='/AnAwesomeDitty/edit']")
      end

      it 'has a close link' do
        @body.should have_tag("a[@rel='close' @href='/AnAwesomeDitty']")
      end

      it 'responds with fourohfour for a non-existent ditty' do
        get '/SubAwesomeDitty'
        last_response.status.should eql(404)
      end
    end


    describe 'GET /AnAwesomeDitty/edit' do
      before(:all) do
        get '/AnAwesomeDitty/edit'
        @response = last_response
        @body     = last_response.body.to_s
      end

      it 'responds successfully if the ditty exists' do
        @response.should be_ok
      end

      it 'returns a ditty edit form' do
        @body.should have_tag('div.ditty_edit')
      end

      it 'returns the ditty edit form' do
        @body.should have_tag('div.ditty_edit') do |ditty|
          ditty.should have_tag('h3', 'AnAwesomeDitty')
        end
      end

      it 'returns a ditty edit form with an id' do
        @body.should have_tag('div#edit_AnAwesomeDitty')
      end

      it 'has a form' do
        @body.should have_tag('div.ditty_edit form')
      end

      it 'has an done link' do
        @body.should have_tag("a[@rel='update' @href='/AnAwesomeDitty']")
      end

      it 'has an cancel link' do
        @body.should have_tag("a[@rel='cancel' @href='/AnAwesomeDitty']")
      end

      it 'has an delete link' do
        @body.should have_tag("a[@rel='destroy' @href='/AnAwesomeDitty']")
      end

      it 'responds with fourohfour for a non-existent ditty' do
        get '/SubAwesomeDitty/edit'
        last_response.status.should eql(404)
      end
    end


    describe 'PUT /AnAwesomeDitty' do
      before(:all) do
        put '/AnAwesomeDitty', :title => 'AnAwesomeDitty', :body => 'A new body'
        @response = last_response
        @body     = last_response.body.to_s
      end

      after(:all) do
        put '/AnAwesomeDitty', :title => 'AnAwesomeDitty', :body => 'See how awesome it is?'
      end


      it 'responds successfully if the ditty exists and the changes are okay' do
        @response.should be_ok
      end

      it 'returns the modified ditty' do
        @body.should have_tag('div.ditty') do |ditty|
          ditty.should have_tag('h3', 'AnAwesomeDitty')
          ditty.should have_tag('div.body') do |body|
            body.inner_html.should match(/A new body/)
          end
        end
      end

      it 'has a edit link' do
        @body.should have_tag("a[@rel='edit' @href='/AnAwesomeDitty/edit']")
      end

      it 'has a close link' do
        @body.should have_tag("a[@rel='close' @href='/AnAwesomeDitty']")
      end

      it 'responds with fourohfour for a non-existent ditty' do
        get '/SubAwesomeDitty'
        last_response.status.should eql(404)
      end

      describe "with validation issues" do
        before(:all) do
          put '/AnAwesomeDitty', :title => 'AnAwesomeDitty', :body => ""
        end

        it 'responds with 400 if there are validation issues' do
          last_response.status.should eql(400)
        end

        it 'returns the validation issues' do
          last_response.body.to_s.should match(/Ditty needs content/)
        end
      end
    end


    describe 'DELETE /AnAwesomeDitty' do
      after(:all) do
        post '/', :title => 'AnAwesomeDitty', :body => 'See how awesome it is?'
      end


      it 'responds successfully if the ditty exists' do
        delete '/AnAwesomeDitty'
        last_response.should be_ok
      end

      it 'deletes the ditty' do
        get '/AnAwesomeDitty'
        last_response.status.should eql(404)
      end

      it 'responds with fourohfour for a non-existent ditty' do
        delete '/SubAwesomeDitty'
        last_response.status.should eql(404)
      end
    end
  end
end
