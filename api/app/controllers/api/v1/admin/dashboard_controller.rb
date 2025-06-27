class Api::V1::Admin::DashboardController < Api::V1::Admin::BaseController
  def index
    render json: {
      status: 'success',
      data: {
        stats: admin_stats,
        recent_activity: recent_activity
      }
    }
  end

  private

  def admin_stats
    {
      total_users: User.count,
      total_devices: Device.count,
      active_devices: Device.active.count,
      total_orders: Order.count,
      total_revenue: Order.where(status: 'paid').sum(:total),
      subscriptions: {
        active: Subscription.active.count,
        past_due: Subscription.past_due.count,
        canceled: Subscription.canceled.count
      }
    }
  end

  def recent_activity
    {
      recent_users: User.order(created_at: :desc).limit(5).as_json(only: [:id, :email, :role, :created_at]),
      recent_orders: Order.order(created_at: :desc).limit(5).as_json(only: [:id, :total, :status, :created_at]),
      recent_devices: Device.order(created_at: :desc).limit(5).as_json(only: [:id, :name, :status, :created_at])
    }
  end
end
