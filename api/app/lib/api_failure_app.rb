class ApiFailureApp < Devise::FailureApp
  def respond
    json_failure
  end

  private

  def json_failure
    self.status = 401
    self.content_type = 'application/json'
    self.response_body = { 
      error: 'Unauthorized', 
      message: 'You need to sign in or sign up before continuing.' 
    }.to_json
  end
end
