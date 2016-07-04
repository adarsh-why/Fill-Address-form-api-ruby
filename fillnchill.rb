require 'sinatra'
require 'shotgun'
require 'open-uri'
require 'json'
require 'securerandom'

def valid key
    File.open('key_db', 'r') do |file|  
        while line = file.gets
            return true if key == line.strip
        end
        return false
    end  
end

def generate_key
    new_key = SecureRandom.hex
    puts new_key.class
    store new_key
    return new_key
end

def store key
    File.open('key_db', 'a') do |file|   
    file.puts key
    end 
end

def whizapi code 
    api_key = 'r7nay4ws9quc159xwikgwbwd'
    JSON.parse(open(
    "https://www.whizapi.com/api/v2/util/ui/in/indian-city-by-postal-code?pin=#{code}&project-app-key=#{api_key}").read)
end

def googleapi code
    JSON.parse(open(
    "http://maps.googleapis.com/maps/api/geocode/json?address=#{code}").read)
end

def process_whizapi data
    city = data["Data"][0]["City"]
    state = data["Data"][0]["State"]
    country = data["Data"][0]["Country"]
    [data["Data"].map{|addr| addr["Address"]}].push(city, state, country)
end

def process_googleapi data
    data = data["results"][0]["address_components"].map{|addr| addr["long_name"]}
    city, state = data[2], data[3]
    country = data.last
    [[data[1]]].push(city, state, country)
end

def api_selecter code
    if code.length == 6
        if code.match(/[a-zA-Z]/)
            process_googleapi googleapi code
        else    
            process_whizapi whizapi code
        end
    else
        process_googleapi googleapi code
    end
end

def api_json data, code
    json = Hash.new
    json[:locality] = data[0]
    json[:city] = data[2]
    json[:state] = data[3]
    json[:pincode] = code
    json[:country] = data.last
    return json.to_json
end

get '/ask-key' do
    @key = generate_key
    erb :newkey
end

get '/api_key=:key/:code' do 
    key = params[:key]
    code = params[:code]
    if valid key
        result = api_selecter code
        return api_json result, code
    else
        return "not a valid key. Visit url.com/ask-key to get key"
    end
end

get '/*' do
    return "try url.com/api_key=[YOUR_API_KEY]/pincode to get address"
end