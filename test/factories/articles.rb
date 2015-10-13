#   Copyright (c) 2012-2015, Fairmondo eG.  This file is
#   licensed under the GNU Affero General Public License version 3 or later.
#   See the COPYRIGHT file for details.

require 'ffaker'

FactoryGirl.define do
  factory :article, aliases: [:appended_object] do
    seller      # alias for User -> see spec/factories/users.rb
    categories { |c| [c.association(:category)] }
    title     { Faker::Lorem.words(rand(3..5)).join(' ').titleize }
    content   { Faker::Lorem.paragraph(rand(7) + 1) }
    condition { %w(new old).sample }
    condition_extra { [:as_good_as_new, :as_good_as_warranted, :used_very_good, :used_good, :used_satisfying, :broken].sample }
    price_cents { Random.new.rand(40000) + 1 }
    vat { [0, 7, 19].sample }
    quantity 1
    state 'active'
    original_id { nil }

    trait :index_article do
      after :create do |article, _evaluator|
        Indexer.index_article article
      end
    end

    basic_price_cents { Random.new.rand(500000) + 1 }
    basic_price_amount { [:kilogram, :gram, :liter, :milliliter, :cubicmeter, :meter, :squaremeter, :portion].sample }

    before :create do |article, _evaluator|
      article.calculate_fees_and_donations
    end

    transport_type1 true
    transport_type1_provider 'DHL Päckchen'
    transport_type1_price_cents { Random.new.rand(200) + 1 }
    transport_details 'transport_details'
    payment_bank_transfer true

    payment_details 'payment_details'

    factory :article_template do
      article_template_name { Faker::Lorem.words(rand(3) + 2) * ' ' }
      state :template
    end

    factory :second_hand_article do
      condition 'old'
      condition_extra 'as_good_as_new'
    end

    factory :no_second_hand_article do
      condition 'new'
    end

    factory :preview_article do
      after(:build) do |article|
        article.state = 'preview'
      end
    end

    factory :closed_article do
      after(:build) do |article|
        article.state = 'closed'
      end
    end

    factory :locked_article do
      after(:build) do |article|
        article.state = 'locked'
      end
    end

    factory :social_production do
      fair true
      fair_kind :social_producer
      association :social_producer_questionnaire
    end

    factory :fair_trust do
      fair true
      fair_kind :fair_trust
      association :fair_trust_questionnaire
    end

    factory :article_with_business_transaction do
      after :create do |article, _evaluator|
        FactoryGirl.create :business_transaction, article: article
      end
    end

    trait :category1 do
      after(:build) do |article|
        article.categories = [Category.find(1)]
      end
    end

    trait :category2 do
      after(:build) do |article|
        article.categories = [Category.find(2)]
      end
    end

    trait :category3 do
      after(:build) do |article|
        article.categories = [Category.find(3)]
      end
    end

    trait :with_child_category do
      categories { |c| [c.association(:category), c.association(:child_category)] }
    end

    trait :with_3_categories do # This should fail validation, so only use with FactoryGirl.build
      categories { |c| [c.association(:category), c.association(:category), c.association(:category)] }
    end

    trait :with_fixture_image do
      after(:build) do |article|
        article.images = [FactoryGirl.build(:article_fixture_image)]
      end
    end

    trait :with_all_transports do
      transport_pickup true
      transport_bike_courier true
      transport_type1 true
      transport_type2 true
      transport_type1_price 20
      transport_type2_price 10
      transport_type1_provider 'DHL'
      transport_type2_provider 'Hermes'
      transport_type1_number { rand(1..10) }
      transport_type2_number { rand(1..10) }
      transport_bike_courier_number { rand(1..10) }
      unified_transport true
      transport_details { Faker::Lorem.paragraph(rand(2..5)) }
    end

    trait :with_all_payments do
      payment_bank_transfer true
      payment_cash true
      payment_paypal true
      payment_cash_on_delivery true
      payment_cash_on_delivery_price 5
      payment_invoice true
      payment_voucher true
      payment_details { Faker::Lorem.paragraph(rand(2..5)) }

      seller { FactoryGirl.create :seller, :paypal_data }
    end

    trait :with_private_user do
      seller { FactoryGirl.create :private_user, :paypal_data } # adding paypal data because it is needed for with_all_transports
    end

    trait :with_legal_entity do
      vat { [7, 19].sample }
      seller { FactoryGirl.create :legal_entity, :paypal_data }
    end

    trait :with_ngo do
      vat { [7, 19].sample }
      seller { FactoryGirl.create :legal_entity, :paypal_data, ngo: true }
    end

    trait :with_friendly_percent do
      friendly_percent 75
      friendly_percent_organisation { FactoryGirl.create :legal_entity, ngo: true }
    end

    trait :with_friendly_percent_and_missing_bank_data do
      friendly_percent 75
      friendly_percent_organisation { FactoryGirl.create :legal_entity, :missing_bank_data, ngo: true }
    end

    trait :simple_fair do
      fair true
      fair_kind :fair_seal
      fair_seal :trans_fair
    end

    trait :simple_ecologic do
      ecologic true
      ecologic_kind :ecologic_seal
      ecologic_seal :bio_siegel
    end

    trait :simple_small_and_precious do
      small_and_precious true
      small_and_precious_eu_small_enterprise true
      small_and_precious_reason 'a' * 151
    end

    trait :with_larger_quantity do
      quantity { (rand(100) + 2) }
    end

    trait :with_custom_seller_identifier do
      custom_seller_identifier { Faker::Lorem.characters(10) }
    end

    trait :with_discount do
      discount { FactoryGirl.create :discount }
    end

    trait :invalid do
      title ''
    end
  end
end
