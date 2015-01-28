require 'rest_client'
require 'pry'

describe 'localhost' do
  before(:all) do
    puts 'You should run "RACK_ENV=production rackup config.ru -p 4567" before spec'
  end

  it 'converts with redirect link' do
    response = RestClient.get('http://localhost:4567/http://bit.ly/1jB2nmf')
    response.size.should > 10000
    response.code.should == 200
  end

  it 'converts https' do
    response = RestClient.get('http://localhost:4567/https://24.media.tumblr.com/b963175d1d3632506a8bafd9ea5029eb/tumblr_n3x2kv7QZo1tq47ppo1_500.gif')
    response.size.should > 10000
    response.code.should == 200
  end

  it 'enables glitch mode' do
    response = RestClient.get('http://localhost:4567/glitch/https://24.media.tumblr.com/b963175d1d3632506a8bafd9ea5029eb/tumblr_n3x2kv7QZo1tq47ppo1_500.gif')
    response.size.should > 10000
    response.code.should == 200
  end

  it 'enables blur mode' do
    response = RestClient.get('http://localhost:4567/glitch/https://24.media.tumblr.com/b963175d1d3632506a8bafd9ea5029eb/tumblr_n3x2kv7QZo1tq47ppo1_500.gif')
    response.size.should > 10000
    response.code.should == 200
  end

  it 'enables with_comments mode' do
    response = RestClient.get('http://localhost:4567/with_comments/https://24.media.tumblr.com/b963175d1d3632506a8bafd9ea5029eb/tumblr_n3x2kv7QZo1tq47ppo1_500.gif')
    response.size.should > 10000
    response.code.should == 200
  end

  it 'does not convert png' do
    expect {
      RestClient.get('http://localhost:4567/http://37.media.tumblr.com/b8e0f7522f720f859569d4ae8068fc20/tumblr_n5loilzE0n1qz529lo1_400.png')
    }.to raise_error(RestClient::BadRequest)
  end

  it 'does not convert 404' do
    expect {
      RestClient.get('http://localhost:4567/http://example.com/hoge')
    }.to raise_error(RestClient::ResourceNotFound)
  end

  it 'does not convert that not robots.txt allowed' do
    expect {
      RestClient.get('http://localhost:4567/http://yelp.com/')
    }.to raise_error(RestClient::Forbidden)
  end

  it 'does not convert image having over max content_length' do
    expect {
      RestClient.get('http://localhost:4567/http://giant.gfycat.com/UnfinishedSelfreliantAnkole.gif')
    }.to raise_error(RestClient::Forbidden)
  end
end
