require 'minigems'
require 'sinatra'
require 'sinatra/test/rspec'
require 'rspec_hpricot_matchers'

Spec::Runner.configure do |config|
  config.include RspecHpricotMatchers
end

describe 'Ditty' do
  require 'ditty'
  before(:all) do
    File.unlink('test.log') if File.exists?('test.log')
    DataMapper::Logger.new('test.log', :debug)
    DataMapper.setup(:default, 'sqlite3::memory:')
  end

  before(:each) do
    DataMapper.auto_migrate!
  end

  describe 'bulk actions' do
    describe 'GET /' do
      describe 'with a HotDitties ditty' do
        before(:each) do
          post_it '/', :title => 'AnAwesomeDitty', :body => 'See how awesome it is?'
          post_it '/', :title => 'PlainDitty', :body => 'Nothing to see here, move along'
          post_it '/', :title => 'ALessThanAwesomeDitty', :body => 'See how un-awesome it is?'
          post_it '/', :title => 'HotDitties', :body => 'AnAwesomeDitty'
          get_it '/'
        end

        it "shows successfully" do
          @response.should be_ok
        end

        it "has a ditty mentioned on the hot ditty page" do
          body.should have_tag('div.ditty#AnAwesomeDitty')
        end

        it "doesn't have a ditty which isn't mentioned" do
          body.should_not have_tag('div.ditty#ALessThanAwesomeDitty')
        end

        it "shows multiple ditties when they're on the list" do
          put_it '/HotDitties', :body => "AnAwesomeDitty\nPlainDitty"
          get_it '/'
          body.should have_tag('div.ditty#PlainDitty')
          body.should have_tag('div.ditty#AnAwesomeDitty')
        end
      end
    end

    describe 'POST /' do
      before(:each) do
        post_it '/', :title => 'AnAwesomeDitty', :body => 'See how awesome it is?'
      end

      it 'creates new ditties by posting to /' do
        @response.should be_ok
      end

      it 'returns a ditty' do
        body.should have_tag('div.ditty')
        body.should have_tag('div.ditty div.body')
      end

      it 'returns the new ditty' do
        body.should have_tag('div.ditty') do |ditty|
          ditty.should have_tag('h3', 'AnAwesomeDitty')
        end
      end

      it 'returns the ditty with an id' do
        body.should have_tag('div#AnAwesomeDitty')
      end

      it 'has a edit link' do
        body.should have_tag("a[@rel='edit' @href='/AnAwesomeDitty/edit']")
      end

      it 'has a close link' do
        body.should have_tag("a[@rel='close' @href='/AnAwesomeDitty']")
      end

      it 'responds with 400 if there are validation issues' do
        post_it '/', :title => 'AnAwesomeDitty'
        @response.status.should eql(400)
      end

      it 'returns the validation issues' do
        post_it '/', :title => 'AnAwesomeDitty'
        @response.should match(/Ditty needs content/)
      end

      it 'duplicate titles are not allowed' do
        post_it '/', :title => 'AnAwesomeDitty', :body => 'See how awesome it is?'
        @response.status.should eql(400)
      end
    end


    describe 'GET /new' do
      before(:each) do
        get_it '/new'
      end

      it 'has an action to supply a new ditty form' do
        @response.should be_ok
      end

      it 'returns a new ditty form' do
        body.should have_tag('div.ditty_edit') do |div|
          div.should have_tag('h3', 'New Ditty')
        end
      end

      it 'it returns a new ditty form with an actual form!' do
        body.should have_tag('div.ditty_edit form[@action="/"]')
      end

      it 'has an input field for a ditty title' do
        body.should have_tag('form[@action="/"] input[@name="ditty_title"]')
      end

      it 'has an input field for a ditty title which is empty when no param is passed' do
        body.should have_tag('form[@action="/"] input[@name="ditty_title" @value=""]')
      end

      it 'fills in the title when the param is passed' do
        get_it '/new?title=YayDitty'
        body.should have_tag('form[@action="/"] input[@name="ditty_title" @value="YayDitty"]')
      end

    end

  end

  describe 'individual ditties' do
    before(:each) do
      Ditty.create(:title => 'AnAwesomeDitty', :body => 'See how awesome it is?')
      Ditty.create(:title => 'LinkTestingDitty', :body => 'Have you seen AnAwesomeDitty ?')
    end

    describe 'get' do
      before(:each) do
        get_it '/AnAwesomeDitty'
      end
      it 'responds successfully if the ditty exists' do
        @response.should be_ok
      end

      it 'returns a ditty' do
        body.should have_tag('div.ditty')
        body.should have_tag('div.ditty div.body')
      end

      it 'returns the ditty' do
        body.should have_tag('div.ditty') do |ditty|
          ditty.should have_tag('h3', 'AnAwesomeDitty')
          ditty.should have_tag('div.body') do |body|
            body.inner_html.should match(/See how awesome it is\?/)
          end
        end
      end

      it 'returns a ditty with an id' do
        body.should have_tag('div#AnAwesomeDitty')
      end

      it 'has a edit link' do
        body.should have_tag("a[@rel='edit' @href='/AnAwesomeDitty/edit']")
      end

      it 'has a close link' do
        body.should have_tag("a[@rel='close' @href='/AnAwesomeDitty']")
      end

      it 'responds with fourohfour for a non-existent ditty' do
        get_it '/SubAwesomeDitty'
        @response.status.should eql(404)
      end
    end


    describe 'edit' do
      before(:each) do
        get_it '/AnAwesomeDitty/edit'
      end
      it 'responds successfully if the ditty exists' do
        @response.should be_ok
      end

      it 'returns a ditty edit form' do
        body.should have_tag('div.ditty_edit')
      end

      it 'returns the ditty edit form' do
        body.should have_tag('div.ditty_edit') do |ditty|
          ditty.should have_tag('h3', 'AnAwesomeDitty')
        end
      end

      it 'returns a ditty edit form with an id' do
        body.should have_tag('div#edit_AnAwesomeDitty')
      end

      it 'has a form' do
        body.should have_tag('div.ditty_edit form')
      end

      it 'has an done link' do
        body.should have_tag("a[@rel='update' @href='/AnAwesomeDitty']")
      end

      it 'has an cancel link' do
        body.should have_tag("a[@rel='cancel' @href='/AnAwesomeDitty']")
      end

      it 'has an delete link' do
        body.should have_tag("a[@rel='destroy' @href='/AnAwesomeDitty']")
      end

      it 'responds with fourohfour for a non-existent ditty' do
        get_it '/SubAwesomeDitty/edit'
        @response.status.should eql(404)
      end
    end


    describe 'update' do
      before(:each) do
        put_it '/AnAwesomeDitty', :title => 'AnAwesomeDitty', :body => 'A new body'
      end
      it 'responds successfully if the ditty exists and the changes are okay' do
        @response.should be_ok
      end

      it 'returns the modified ditty' do
        body.should have_tag('div.ditty') do |ditty|
          ditty.should have_tag('h3', 'AnAwesomeDitty')
          ditty.should have_tag('div.body') do |body|
            body.inner_html.should match(/A new body/)
          end
        end
      end

      it 'has a edit link' do
        body.should have_tag("a[@rel='edit' @href='/AnAwesomeDitty/edit']")
      end

      it 'has a close link' do
        body.should have_tag("a[@rel='close' @href='/AnAwesomeDitty']")
      end

      it 'responds with fourohfour for a non-existent ditty' do
        get_it '/SubAwesomeDitty'
        @response.status.should eql(404)
      end

      it 'responds with 400 if there are validation issues' do
        put_it '/AnAwesomeDitty', :title => 'AnAwesomeDitty'
        @response.status.should eql(400)
      end
      it 'returns the validation issues' do
        put_it '/AnAwesomeDitty', :title => 'AnAwesomeDitty'
        @response.should match(/Ditty needs content/)
      end
    end


    describe 'delete' do
      it 'responds successfully if the ditty exists' do
        delete_it '/AnAwesomeDitty'
        @response.should be_ok
      end

      it 'deletes the ditty' do
        delete_it '/AnAwesomeDitty'
        get_it '/AnAwesomeDitty'
        @response.status.should eql(404)
      end

      it 'responds with fourohfour for a non-existent ditty' do
        delete_it '/SubAwesomeDitty'
        @response.status.should eql(404)
      end

    end
  end
end
