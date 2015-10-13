#   Copyright (c) 2012-2015, Fairmondo eG.  This file is
#   licensed under the GNU Affero General Public License version 3 or later.
#   See the COPYRIGHT file for details.

FactoryGirl.define do
  factory :content do
    sequence(:key) { |n| "page#{n}" }
    body { Faker::Lorem.paragraph(rand(7) + 1) }
  end
end
