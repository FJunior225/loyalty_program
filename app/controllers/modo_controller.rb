class ModoController < ApplicationController::Base

  def create

    @card = request["uid"]
    @merch_id = request["merchId"]
    @amount_due = request["ammountDue"]

    uri = URI('https://hack.modoapi.com/1.0.0-dev/people/register')

    # Create client
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    dict = {
            "phone": @card,
            
          }
    body = JSON.dump(dict)

    # Create Request
    req =  Net::HTTP::Post.new(uri)
    # Add headers
    req.add_field "Authorization", "Token " + token
    # Add headers
    req.add_field "Content-Type", "application/json"
    # Set body
    req.body = body

    # Fetch Request
    res = http.request(req)
    puts "Response HTTP Status Code: #{res.code}"
    puts "Response HTTP Response Body: #{res.body}"
    body = JSON.parse(res.body)
    @account_id = body["response_data"]["account_id"]

    # make call to get vault
    uri = URI('https://hack.modoapi.com/1.0.0-dev/vault/fetch')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    dict = {
      "vault_types": [
        "ACME_LOYALTY"
        ],
        "account_id": @account_id    
      }
    body = JSON.dump(dict)

    # Create Request
    req =  Net::HTTP::Post.new(uri)
    # Add headers
    req.add_field "Authorization", "Token " + token
    # Add headers
    req.add_field "Content-Type", "application/json"
    # Set body
    req.body = body

    # Fetch Request
    res = http.request(req)
    response = JSON.parse(res.body)
    response_data = response["response_data"]
    if response_data.empty? #member is not signed up
      # make post to vault
      uri = URI('https://hack.modoapi.com/1.0.0-dev/vault/add')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      dict = {
        "items": [
          {
            "vault_type": "ACME_LOYALTY",
            "description": "Sample Card",
            "encrypted_data": {},
            "account_id": @account_id,
            "unencrypted_json": {
              "merch_id": 001,
            "tap_id": 1234,
            "amount_due": "get from initial tap"
            },
            "end_of_life": 1474480166,
            "disable": 0,
            "sequestered": 0
          }
        ]    
      }
      body = JSON.dump(dict)

      # Create Request
      req =  Net::HTTP::Post.new(uri)
      # Add headers
      req.add_field "Authorization", "Token " + token
      # Add headers
      req.add_field "Content-Type", "application/json"
      # Set body
      req.body = body

      # Fetch Request
      res = http.request(req)
      response = JSON.parse(res.body)
      response_data = response["response_data"]
      @vault_id = response_data["vault_id"]
      # vault is now setup and customer can just pay
      # make call to adjust vault balance

      uri = URI('https://hack.modoapi.com/1.0.0-dev/vault/adjust_demo_balance')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      dict = {
        "item_id": @vault_id,
        "adjustment": "-100" 
         # add logic for points conversion
      }
      body = JSON.dump(dict)

      # Create Request
      req =  Net::HTTP::Post.new(uri)
      # Add headers
      req.add_field "Authorization", "Token " + token
      # Add headers
      req.add_field "Content-Type", "application/json"
      # Set body
      req.body = body

      # Fetch Request
      res = http.request(req)
      response = JSON.parse(res.body)
      response_data = response["response_data"]
      status_code = response["status_code"]
    else
      # make call to get loyalty points
      uri = URI('https://hack.modoapi.com/1.0.0-dev/vault/get_balance')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      dict = {
        "item_ids": [
          @vault_id
        ]
      }
      body = JSON.dump(dict)

      # Create Request
      req =  Net::HTTP::Post.new(uri)
      # Add headers
      req.add_field "Authorization", "Token " + token
      # Add headers
      req.add_field "Content-Type", "application/json"
      # Set body
      req.body = body

      # Fetch Request
      res = http.request(req)
      response = JSON.parse(res.body)
      status_code = response["status_code"]
      response_data = response["response_data"]
      @balance = response_data[@vault_id]["balance"]
      if @balance > @amount_due 
        # send request to ingenico 
        render :json => { account_id, amount, merch_id, yes }
        
      else
        render :json => { account_id, amount, merch_id, no }

      end
    rescue StandardError => e
      puts "HTTP Request failed (#{e.message})"
  end

  # def update
  #   uri = URI('https://hack.modoapi.com/1.0.0-dev/vault/fetch')

  #   # Create client
  #   http = Net::HTTP.new(uri.host, uri.port)
  #   http.use_ssl = true
  #   http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  #   dict = {
  #     "vault_types": [
  #       "ACME_LOYALTY"
  #       ],
  #     "account_id": @account_id,
  #     "just_count": 1
  #   }
  #   body = JSON.dump(dict)

  #   # Create Request
  #   req =  Net::HTTP::Post.new(uri)
  #   # Add headers
  #   req.add_field "Authorization", "Token " + token
  #   # Add headers
  #   req.add_field "Content-Type", "application/json"
  #   # Set body
  #   req.body = body

  #   # Fetch Request
  #   res = http.request(req)
  #   puts "Response HTTP Status Code: #{res.code}"
  #   puts "Response HTTP Response Body: #{res.body}"
  #   body = JSON.parse(res.body)
  #   @count = body["response_data"]["count"].to_i
  #   if @count > 0 

  #   else

  #   end
  # rescue StandardError => e
  #   puts "HTTP Request failed (#{e.message})"
  # end



  private

  def authentication
    api_key = "b255a6fd-621a-4046-94b9-42236a4f05b7"
    secret_key = "LFBq5g+7TLHVxroMqogudlobaTOxcZ4dRx435/PgOMU3Rf8w+L1UFeAMaEhxspH/d3zOVBjjaa8PyNSgVBkmpA=="

    payload = { api_key: api_key, iat: Time.now }

    token = JWT.encode(payload, secret_key, 'HS256')
  end
  # decoded_token = JWT.decode token, secret_key, true, { algorithm: 'HS256' }

end