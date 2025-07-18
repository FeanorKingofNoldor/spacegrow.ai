# app/policies/admin/order_management_policy.rb
module Admin
  class OrderManagementPolicy < ApplicationPolicy
    attr_reader :user, :order

    def initialize(user, order)
      @user = user
      @order = order
    end

    def index?
      user.admin?
    end

    def show?
      user.admin?
    end

    def update_status?
      user.admin? && order_modifiable?
    end

    def refund?
      user.admin? && can_process_refunds? && order_refundable?
    end

    def retry_payment?
      user.admin? && order&.status == 'payment_failed'
    end

    def view_financial_details?
      user.admin?
    end

    def export_order_data?
      user.admin?
    end

    def bulk_operations?
      user.admin?
    end

    def analytics?
      user.admin?
    end

    private

    def order_modifiable?
      return true unless order
      !%w[refunded].include?(order.status)
    end

    def order_refundable?
      return false unless order
      %w[completed shipped delivered].include?(order.status) && 
      (order.refund_amount.nil? || order.refund_amount < order.total)
    end

    def can_process_refunds?
      # Additional business logic for refund permissions
      # Could be based on user role, order amount, etc.
      user.admin?
    end

    class Scope < Scope
      def resolve
        if user.admin?
          scope.all
        else
          scope.none
        end
      end
    end
  end
end