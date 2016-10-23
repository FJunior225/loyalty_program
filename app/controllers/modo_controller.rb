class ModoController < ApplicationController
  # before_action :authentication
  
  NEW_USER = 'https://hack.modoapi.com/1.0.0-dev/people/register'
  GET_VAULT = 'https://hack.modoapi.com/1.0.0-dev/vault/fetch'
  POST_VAULT = 'https://hack.modoapi.com/1.0.0-dev/vault/add'
  ADJUST_BALANCE = 'https://hack.modoapi.com/1.0.0-dev/vault/adjust_demo_balance'
  GET_BALANCE = 'https://hack.modoapi.com/1.0.0-dev/vault/get_balance'

  def create
    payload = { api_key: ENV["API_KEY"], iat: Time.now }
    token = JWT.encode(payload, ENV["SECRET_KEY"], 'HS256')
    @card = request["uid"]
    @merch_id = 0100
    @amount_due = request["amountDue"].to_i

    # Create new Use
    uri = URI(NEW_USER)

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
    body = JSON.parse(res.body)
    @account_id = body["response_data"]["account_id"]

    # make call to get vault
    uri2 = URI(GET_VAULT)
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
    if response_data.empty? #member is not signed up
      # make post to vault
      uri3 = URI(POST_VAULT)
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
              "tap_id": @card,
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
      response_data = response["response_data"]
      @vault_id = response_data[0]["vault_id"]
      # vault is now setup and customer can just pay
      # make call to adjust vault balance

      uri4 = URI(ADJUST_BALANCE)
      http = Net::HTTP.new(uri4.host, uri4.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      dict = {
        "item_id": @vault_id,
        "adjustment": "+#{@amount_due}"
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
      @balance = response_data["balance"].to_i
      status_code = response["status_code"]
      render :json => { balance: @balance, complete: "Vault Created Loyalties Updated"}
    else  
      @vault_id = response_data[0]["vault_id"]
      # make call to get loyalty points
      uri5 = URI(GET_BALANCE)
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
      @balance = response_data[@vault_id]["balance"].to_i

      if @balance > @amount_due 
        # send request to ingenico 
        render :json => { item_id: @vault_id, amount_due: @amount_due, balance: @balance, covered: "yes" }
      else
        render :json => { item_id: @vault_id, amount_due: @amount_due, balance: @balance, covered: "no" }
      end
    end
  rescue StandardError => e
    puts "HTTP Request failed (#{e.message})"
  end

end
