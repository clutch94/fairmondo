#
#
# == License:
# Fairnopoly - Fairnopoly is an open-source online marketplace.
# Copyright (C) 2013 Fairnopoly eG
#
# This file is part of Fairnopoly.
#
# Fairnopoly is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairnopoly is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairnopoly.  If not, see <http://www.gnu.org/licenses/>.
#
module Article::Attributes
  extend ActiveSupport::Concern

  included do

    #common fields

    attr_accessible :title, :content, :condition  ,:condition_extra  , :quantity , :transaction_attributes
    auto_sanitize :content, method: 'tiny_mce'
    auto_sanitize :title

    #title



    validates_presence_of :title , :content
    validates_length_of :title, :minimum => 6, :maximum => 65


    #conditions

    validates_presence_of :condition
    validates_presence_of :condition_extra , if: :old?
    enumerize :condition, in: [:new, :old], predicates:  true
    enumerize :condition_extra, in: [:as_good_as_new, :as_good_as_warranted ,:used_very_good , :used_good, :used_satisfying , :broken] # refs #225

    #money_rails and price

    attr_accessible :price_cents , :currency, :price, :vat

    validates_presence_of :price_cents
    validates_numericality_of :price, greater_than_or_equal_to: 0

    monetize :price_cents, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 10000 }


    # vat (Value Added Tax)

    validates :vat , presence: true , inclusion: { in: [0,7,19] },  if: :has_legal_entity_seller?


    # basic price
    attr_accessible :basic_price, :basic_price_cents, :basic_price_amount

    monetize :basic_price_cents, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 10000 }, :allow_nil => true

    enumerize :basic_price_amount, in: [:kilogram, :gram, :liter, :milliliter, :cubicmeter, :meter, :squaremeter, :portion ]



    # =========== Transport =============
    TRANSPORT_TYPES = [:pickup, :insured, :uninsured]

    #transport
    attr_accessible :default_transport, :transport_pickup,
                    :transport_insured, :transport_insured_price_cents,
                    :transport_insured_price, :transport_insured_provider,
                    :transport_uninsured, :transport_uninsured_price_cents,
                    :transport_uninsured_price, :transport_uninsured_provider,
                    :transport_details

    auto_sanitize :transport_insured_provider, :transport_uninsured_provider, :transport_details

    enumerize :default_transport, in: TRANSPORT_TYPES

    validates_presence_of :default_transport
    validates :transport_insured_price, :transport_insured_provider, :presence => true ,:if => :transport_insured
    validates :transport_uninsured_price, :transport_uninsured_provider, :presence => true ,:if => :transport_uninsured
    validates :transport_details, :length => { :maximum => 2500 }

    monetize :transport_uninsured_price_cents, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 500 }, :allow_nil => true
    monetize :transport_insured_price_cents, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 500 }, :allow_nil => true

    validate :default_transport_selected


    # ================ Payment ====================
    PAYMENT_TYPES = [:bank_transfer, :cash, :paypal, :cash_on_delivery, :invoice]

    #payment
    attr_accessible :payment_details ,
                    :payment_bank_transfer,
                    :payment_cash,
                    :payment_paypal,
                    :payment_cash_on_delivery, :payment_cash_on_delivery_price , :payment_cash_on_delivery_price_cents,
                    :payment_invoice
    auto_sanitize :payment_details

    validates :payment_cash_on_delivery_price, :presence => true ,:if => :payment_cash_on_delivery

    before_validation :set_sellers_nested_validations

    monetize :payment_cash_on_delivery_price_cents, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 500 }, :allow_nil => true

    validates :payment_details, :length => { :maximum => 2500 }

    validates_presence_of :quantity
    validates_numericality_of :quantity, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 10000
    validate :payment_method_checked
  end

  def set_sellers_nested_validations
    seller.bank_account_validation = true if payment_bank_transfer
    seller.paypal_validation = true if payment_paypal
  end

  def has_legal_entity_seller?
    self.seller.is_a?(LegalEntity)
  end


  # Gives the price of the article minus taxes
    #
    # @api public
    # @return [Money]
    def price_without_vat
      self.price * ( 100 - self.vat ) / 100
    end

    # Gives the amount of money for an article that goes towards taxes
    #
    # @api public
    # @return [Money]
    def vat_price
      self.price * self.vat / 100
    end

    # Function to calculate total price for an article.
    # Note: Params should have already been validated.
    #
    # @api public
    # @param selected_transport [String] Transport type
    # @param selected_payment [String] Payment type
    # @return [Money] Total billed price
    def total_price selected_transport, selected_payment
      total = self.price + self.transport_price(selected_transport)
      total += self.payment_cash_on_delivery_price if selected_payment == "cash_on_delivery"
      total
    end

    # Gives the shipping cost for a specified transport type
    #
    # @api public
    # @param transport_type [String] The transport type to look up
    # @return [Money] The shipping price
    def transport_price transport_type = self.default_transport
      case transport_type
      when "insured"
        transport_insured_price
      when "uninsured"
        transport_uninsured_price
      else
        Money.new 0
      end
    end

    # Gives the shipping provider for a specified transport type
    #
    # @api public
    # @param transport_type [String] The transport type to look up
    # @return [Money] The shipping provider
    def transport_provider transport_type = self.default_transport
      case transport_type
      when "insured"
        transport_insured_provider
      when "uninsured"
        transport_uninsured_provider
      else
        nil
      end
    end

    # Returns an array with all selected transport types.
    # Default transport will be the first element.
    #
    # @api public
    # @return [Array] An array with selected transport types.
    def selectable_transports
      selectable "transport"
    end

    # Returns an array with all selected payment types.
    # Default payment will be the first element.
    #
    # @api public
    # @return [Array] An array with selected payment types.
    def selectable_payments
      selectable "payment"
    end

  private

    def default_transport_selected
      if self.default_transport
        unless self.send("transport_#{self.default_transport}")
          errors.add(:default_transport, I18n.t("errors.messages.invalid_default_transport"))
        end
      end
    end

    def payment_method_checked
      unless self.payment_bank_transfer || self.payment_paypal || self.payment_cash || self.payment_cash_on_delivery || self.payment_invoice
        errors.add(:payment_details, I18n.t("article.form.errors.invalid_payment_option"))
      end
    end

    # DRY method for selectable_transports and selectable_payments
    #
    # @api private
    # @return [Array] An array with selected attribute types
    def selectable attribute
      # First get all selected attributes
      output = []
      eval("#{attribute.upcase}_TYPES").each do |e|
        output << e if self.send "#{attribute}_#{e}"
      end

      # Now shift the default to be the first element
      if attribute == "transport"
        output.unshift output.delete_at output.index send("default_transport").to_sym
      else
        output
      end
    end



end
