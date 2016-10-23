
class MembershipController < ApplicationController

  ADJUST_BALANCE = 'https://hack.modoapi.com/1.0.0-dev/vault/adjust_demo_balance'

  def create
    payload = { api_key: ENV["API_KEY"], iat: Time.now }
    token = JWT.encode(payload, ENV["SECRET_KEY"], 'HS256')

    @vault_id = request["item_id"]
    @amount_due = request["amount_due"]
    @covered = request["covered"]
    puts @vault_id
    puts @amount_due
    puts @covered

    uri = URI(ADJUST_BALANCE)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    
    if @covered == "yes"
      puts "0"
      dict = {
        "item_id": @vault_id,
        "adjustment": "-#{@amount_due}"
         # add logic for points conversion
      }
      puts "1"
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

      puts "HELLO"
      render :json => { complete: "Funds deducted Loyalties Updated"}
    else
      dict = {
        "item_id": @vault_id,
        "adjustment": "+#{@amount_due}"
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
      render :json => { complete: "Funds added Loyalties Updated"}
    end
  end

end