# app/serializers/user_serializer.rb
class UserSerializer
  def initialize(user)
    @user = user
  end

  def serializable_hash
    {
      data: {
        attributes: {
          id: @user.id,
          email: @user.email,
          role: @user.role,
          created_at: @user.created_at,
          devices_count: @user.devices_count
        }
      }
    }
  end
end