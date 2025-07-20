# db/seeds/users.rb
regular_user_email = 'user@user.com'
pro_user_email = 'pro@pro.com'

# Create a regular user if it doesn't exist
unless User.exists?(email: regular_user_email)
  User.create!(
    email: regular_user_email,
    password: 'Password1!',
    password_confirmation: 'Password1!',
    role: 'user'
  )
end

# Create a pro user if it doesn't exist
unless User.exists?(email: pro_user_email)
  User.create!(
    email: pro_user_email,
    password: 'Password1!',
    password_confirmation: 'Password1!',
    role: 'pro'
  )
end