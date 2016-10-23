class ModoController < ApplicationController::Base

  def create
    @person = 
  end

  private

  api_key = "b255a6fd-621a-4046-94b9-42236a4f05b7"
  secret_key = "LFBq5g+7TLHVxroMqogudlobaTOxcZ4dRx435/PgOMU3Rf8w+L1UFeAMaEhxspH/d3zOVBjjaa8PyNSgVBkmpA=="

  payload = {api_key: api_key, iat: Time.now}

  token = JWT.encode(payload, secret_key, 'HS256')

  HTTP.auth('Token ' + token)
  body = {
    "phone": 5551235500,
    "fname": "FJ",
    "lname": "Collins"
  }
  response = HTTP.post("https://hack.modoapi.com/1.0.0-dev/people/register", json: body)
  
  begin
    # create HTTP client with persistent connection to api.icndb.com:
    http = HTTP.persistent("https://hack.modoapi.com/1.0.0-dev/people/register")

    # issue multiple requests using same connection:
    jokes = 100.times.map { http.post("https://hack.modoapi.com/1.0.0-dev/people/register", json: body).parse }
  ensure
    # close underlying connection when you don't need it anymore
    http.close if http
  end


end