require 'minigems'
require 'sinatra'
require 'spec/interop/test'
require 'sinatra/test/unit'

describe 'Ditty' do
  require 'ditty'
  before(:all) do
    DataMapper::Logger.new('test.log', :debug)
    DataMapper.setup(:default, 'sqlite3::memory:')
  end

  before(:each) do
    DataMapper.auto_migrate!
  end

  it 'has an action to supply a new ditty form' do
    get_it '/ditty/new'
    @response.should be_ok
  end

  describe 'individual ditties' do
    before(:each) do
      Ditty.create(:title => 'AnAwesomeDitty', :body => 'See how awesome it is?')
      Ditty.create(:title => 'LinkTestingDitty', :body => 'Have you seen AnAwesomeDitty ?')
    end

    describe 'get' do
      before(:each) do
        get_it '/ditty/1'
      end
      it 'responds successfully if the ditty exists' do
        @response.should be_ok
      end

      it 'returns the ditty' do
        @response.should match(/<h3>AnAwesomeDitty<\/h3>/m)
        @response.should match(/<div[^>]*class='ditty'[^>]*>/m)
      end

      it 'has a edit link' do
        @response.should match(/a rel='edit' href='\/ditty\/1\/edit'/m)
      end

      it 'has a close link' do
        @response.should match(/a rel='close' href='\/ditty\/1'/m)
      end

      it 'responds with fourohfour for a non-existent ditty' do
        get_it '/ditty/3'
        @response.status.should eql(404)
      end
    end


    describe 'edit' do
      before(:each) do
        get_it '/ditty/1/edit'
      end
      it 'responds successfully if the ditty exists' do
        @response.should be_ok
      end

      it 'returns the ditty' do
        @response.should match(/<h3>AnAwesomeDitty<\/h3>/m)
        @response.should match(/<div[^>]*class='ditty_edit'[^>]*>/m)
        @response.should match(/See how awesome it is/m)
      end

      it 'has a done link' do
        @response.should match(/a rel='update' href='\/ditty\/1'/m)
      end

      it 'has a cancel link' do
        @response.should match(/a rel='cancel' href='\/ditty\/1'/m)
      end

      it 'has a delete link' do
        @response.should match(/a rel='destroy' href='\/ditty\/1'/m)
      end

      it 'responds with fourohfour for a non-existent ditty' do
        get_it '/ditty/3/edit'
        @response.status.should eql(404)
      end
    end


    describe 'update' do
      before(:each) do
        put_it '/ditty/1', :title => 'AnAwesomeDitty', :body => 'A new body'
      end
      it 'responds successfully if the ditty exists and the changes are okay' do
        @response.should be_ok
      end

      it 'returns the modified ditty' do
        @response.should match(/<h3>AnAwesomeDitty<\/h3>/m)
        @response.should match(/<div[^>]*class='ditty'[^>]*>/m)
        @response.should match(/A new body/m)
      end

      it 'has a edit link' do
        @response.should match(/a rel='edit' href='\/ditty\/1\/edit'/m)
      end

      it 'has a close link' do
        @response.should match(/a rel='close' href='\/ditty\/1'/m)
      end

      it 'responds with fourohfour for a non-existent ditty' do
        get_it '/ditty/3'
        @response.status.should eql(404)
      end

      it 'responds with 400 if there are validation issues' do
        put_it '/ditty/1', :title => 'AnAwesomeDitty'
        @response.status.should eql(400)
      end
      it 'returns the validation issues' do
        put_it '/ditty/1', :title => 'AnAwesomeDitty'
        @response.should match(/Ditty needs content/)
      end
    end


    describe 'delete' do
      it 'responds successfully if the ditty exists' do
        delete_it '/ditty/1'
        @response.should be_ok
      end

      it 'deletes the ditty' do
        delete_it '/ditty/1'
        Ditty.first(:title => 'AnAwesomeDitty').should be_nil
      end

      it 'responds with fourohfour for a non-existent ditty' do
        delete_it '/ditty/3'
        @response.status.should eql(404)
      end

    end
  end
end
