class Api::V1::Store::StoreController < Api::V1::Store::BaseController
  def index
    products = Product.active.includes(:device_type)
    
    render json: {
      status: 'success',
      data: {
        products: products.map { |product| product_json(product) }
      }
    }
  end

  def show
    product = Product.active.find(params[:id])
    
    render json: {
      status: 'success',
      data: {
        product: detailed_product_json(product)
      }
    }
  end

  private

  def product_json(product)
    {
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      device_type: product.device_type&.name,
      active: product.active
    }
  end

  def detailed_product_json(product)
    product_json(product).merge({
      device_type_details: product.device_type ? {
        id: product.device_type.id,
        description: product.device_type.description,
        configuration: product.device_type.configuration
      } : nil
    })
  end
end
