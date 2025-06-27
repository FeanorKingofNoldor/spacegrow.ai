FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2025-06-26 17:29:39" }
  end
end
