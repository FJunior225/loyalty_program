class ModoController < ApplicationController
  # before_action :authentication

  def create

    payload = { api_key: ENV["api_key"], iat: Time.now }

    token = JWT.encode(payload, ENV["secret_key"], 'HS256')

    @card = request["uid"]
    @merch_id = request["merchId"]
    @amount_due = request["amountDue"].to_i

    # Create new Use
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
    uri2 = URI('https://hack.modoapi.com/1.0.0-dev/vault/fetch')
    http = Net::HTTP.new(uri2.host, uri2.port)
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
    req =  Net::HTTP::Post.new(uri2)
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
    puts "response_data: #{response_data}"
    if response_data.empty? #member is not signed up
      # make post to vault
      puts "HERE IF"
      uri3 = URI('https://hack.modoapi.com/1.0.0-dev/vault/add')
      http = Net::HTTP.new(uri3.host, uri3.port)
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
              "merch_id": @merch_id,
            "tap_id": @phone,
            "amount_due": @amount_due
            },
            "end_of_life": 1474480166,
            "disable": 0,
            "sequestered": 0
          }
        ]
      }
      body = JSON.dump(dict)

      # Create Request
      req =  Net::HTTP::Post.new(uri3)
      # Add headers
      req.add_field "Authorization", "Token " + token
      # Add headers
      req.add_field "Content-Type", "application/json"
      # Set body
      req.body = body

      # Fetch Request
      res = http.request(req)
      response = JSON.parse(res.body)
      puts "asjdfadksjhfkadsfja;s"
      response_data = response["response_data"]
      @vault_id = response_data["vault_id"]
      # vault is now setup and customer can just pay
      # make call to adjust vault balance

      uri4 = URI('https://hack.modoapi.com/1.0.0-dev/vault/adjust_demo_balance')
      http = Net::HTTP.new(uri4.host, uri4.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      dict = {
        "item_id": @vault_id,
        "adjustment": "-100"
         # add logic for points conversion
      }
      body = JSON.dump(dict)

      # Create Request
      req =  Net::HTTP::Post.new(uri4)
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
      @vault_id = response_data[0]["vault_id"]
      # make call to get loyalty points
      uri5 = URI('https://hack.modoapi.com/1.0.0-dev/vault/get_balance')
      http = Net::HTTP.new(uri5.host, uri5.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      dict = {
        "item_ids": [
          @vault_id
        ]
      }
      body = JSON.dump(dict)
      # Create Request
      req =  Net::HTTP::Post.new(uri5)
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
      puts "RESPONSE"
      puts "#{response_data}"
      @balance = response_data[@vault_id]["balance"].to_i
      puts "----------------------"
      if @balance > @amount_due
        puts "HITTTTT"
        # send request to ingenico
        render :json => { account_id: @account_id, amount: @amount_due, merch_id: @merch_id, covered: "yes" }

      else
        render :json => { account_id: @account_id, amount: @amount_due, merch_id: @merch_id, covered: "no" }
      end
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


  # decoded_token = JWT.decode token, secret_key, true, { algorithm: 'HS256' }

end
