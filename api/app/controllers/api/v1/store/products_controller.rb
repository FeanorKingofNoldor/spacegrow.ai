# app/controllers/api/v1/store/products_controller.rb
class Api::V1::Store::ProductsController < Api::V1::Store::BaseController
  def index
    @products = Product.active.includes(:device_type)
    
    # Apply filters
    @products = filter_by_category(@products) if params[:category].present?
    @products = filter_by_search(@products) if params[:search].present?
    @products = filter_by_price(@products) if params[:min_price].present? || params[:max_price].present?
    @products = filter_by_stock(@products) if params[:stock_status].present?
    
    # Apply sorting
    @products = apply_sorting(@products)
    
    render json: {
      status: 'success',
      data: {
        products: @products.map { |product| enhanced_product_json(product) },
        categories: available_categories,
        total: @products.count,
        filters: {
          categories: available_categories,
          price_range: {
            min: Product.active.minimum(:price) || 0,
            max: Product.active.maximum(:price) || 1000
          },
          stock_info: {
            total_products: Product.active.count,
            in_stock: Product.active.in_stock.count,
            low_stock: Product.active.low_stock.count,
            out_of_stock: Product.active.out_of_stock.count
          }
        }
      }
    }
  end

  def show
    @product = Product.active.includes(:device_type).find(params[:id])
    
    render json: {
      status: 'success',
      data: {
        product: detailed_product_json(@product)
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'Product not found'
    }, status: :not_found
  end

  def featured
    @featured_products = Product.active
                               .featured
                               .includes(:device_type)
                               .limit(6)
    
    # If no featured products, fall back to newest
    if @featured_products.empty?
      @featured_products = Product.active
                                 .includes(:device_type)
                                 .order(created_at: :desc)
                                 .limit(6)
    end
    
    render json: {
      status: 'success',
      data: {
        products: @featured_products.map { |product| enhanced_product_json(product) }
      }
    }
  end

  # New endpoint for checking stock availability
  def check_stock
    @product = Product.active.find(params[:id])
    quantity = params[:quantity]&.to_i || 1
    
    render json: {
      status: 'success',
      data: {
        product_id: @product.id,
        available: @product.can_order?(quantity),
        stock_quantity: @product.stock_quantity,
        requested_quantity: quantity,
        stock_status: @product.stock_status,
        stock_description: @product.stock_description
      }
    }
  end

  private

  def filter_by_category(products)
    if params[:category] == 'all'
      products
    else
      products.joins(:device_type).where(device_types: { name: params[:category] })
    end
  end

  def filter_by_search(products)
    search_term = "%#{params[:search].downcase}%"
    products.where(
      "LOWER(products.name) LIKE ? OR LOWER(products.description) LIKE ?",
      search_term, search_term
    )
  end

  def filter_by_price(products)
    products = products.where("price >= ?", params[:min_price]) if params[:min_price].present?
    products = products.where("price <= ?", params[:max_price]) if params[:max_price].present?
    products
  end

  def filter_by_stock(products)
    case params[:stock_status]
    when 'in_stock'
      products.in_stock
    when 'low_stock'
      products.low_stock
    when 'out_of_stock'
      products.out_of_stock
    else
      products
    end
  end

  def apply_sorting(products)
    case params[:sort]
    when 'price_asc'
      products.order(price: :asc)
    when 'price_desc'
      products.order(price: :desc)
    when 'name_asc'
      products.order(name: :asc)
    when 'name_desc'
      products.order(name: :desc)
    when 'newest'
      products.order(created_at: :desc)
    when 'stock_asc'
      products.order(stock_quantity: :asc)
    when 'stock_desc'
      products.order(stock_quantity: :desc)
    else
      products.order(:name)
    end
  end

  def available_categories
    DeviceType.joins(:products)
              .where(products: { active: true })
              .distinct
              .pluck(:name)
  end

  def enhanced_product_json(product)
    {
      id: product.id.to_s,
      name: product.name,
      description: product.description,
      price: product.price.to_f,
      image: product_image_url(product),
      category: product.device_type&.name || 'Accessories',
      features: extract_features(product),
      # Stock information
      in_stock: product.in_stock?,
      stock_quantity: product.stock_quantity,
      stock_status: product.stock_status,
      stock_description: product.stock_description,
      low_stock_threshold: product.low_stock_threshold,
      # Other attributes
      featured: product.featured,
      active: product.active,
      created_at: product.created_at.iso8601,
      updated_at: product.updated_at.iso8601
    }
  end

  def detailed_product_json(product)
    enhanced_product_json(product).merge({
      detailed_description: product.detailed_description || product.description,
      specifications: product.device_type&.configuration || {},
      related_products: related_products(product).map { |p| enhanced_product_json(p) }
    })
  end

  def product_image_url(product)
    if product.respond_to?(:image) && product.image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(product.image, only_path: true)
    else
      case product.device_type&.name
      when 'Environmental Monitor V1'
        'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=400&h=400&fit=crop'
      when 'Liquid Monitor V1'
        'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400&h=400&fit=crop'
      else
        'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400&h=400&fit=crop'
      end
    end
  end

  def extract_features(product)
    if product.device_type&.configuration&.dig('supported_sensor_types')
      features = []
      product.device_type.configuration['supported_sensor_types'].each do |name, config|
        features << "#{name} (#{config['unit']})" if config['required']
      end
      features
    else
      case product.device_type&.name
      when 'Environmental Monitor V1'
        ['Temperature Sensor', 'Humidity Sensor', 'Pressure Sensor', 'Wi-Fi Connectivity']
      when 'Liquid Monitor V1'
        ['pH Sensor', 'EC Sensor', 'Temperature Sensor', 'Automatic Dosing']
      else
        ['Professional Quality', 'Easy Installation', 'Long Lasting']
      end
    end
  end

  def related_products(product)
    Product.active
           .includes(:device_type)
           .where.not(id: product.id)
           .where(device_type: product.device_type)
           .limit(4)
  end
end