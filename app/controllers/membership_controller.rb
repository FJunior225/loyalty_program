
class MembershipController < ApplicationController

  ADJUST_BALANCE = 'https://hack.modoapi.com/1.0.0-dev/vault/adjust_demo_balance'

  def create
    payload = { api_key: ENV["api_key"], iat: Time.now }
    token = JWT.encode(payload, ENV["secret_key"], 'HS256')

    @vault_id = request["item_id"]
    @amount_due = request["amount_due"]
    @covered = request["covered"]

    uri = URI(ADJUST_BALANCE)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    
    if @covered == "yes"
      dict = {
        "item_id": @vault_id,
        "adjustment": "-#{@amount_due}"
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