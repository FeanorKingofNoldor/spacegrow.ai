class Api::V1::Frontend::PagesController < Api::V1::Frontend::ProtectedController
  def index
    render json: {
      status: 'success',
      message: 'Welcome to SpaceGrow API'
    }
  end

  def docs
    render json: {
      status: 'success',
      data: {
        title: 'API Documentation',
        sections: [
          'Getting Started',
          'Authentication',
          'Devices',
          'Sensors',
          'Commands'
        ]
      }
    }
  end

  def api
    render json: {
      status: 'success',
      data: {
        title: 'API Reference',
        version: 'v1',
        base_url: '/api/v1'
      }
    }
  end

  def devices
    render json: {
      status: 'success',
      data: {
        title: 'Device Documentation',
        device_types: DeviceType.all.map { |dt| { name: dt.name, description: dt.description } }
      }
    }
  end

  def sensors
    render json: {
      status: 'success',
      data: {
        title: 'Sensor Documentation',
        sensor_types: SensorType.all.map { |st| { name: st.name, unit: st.unit } }
      }
    }
  end

  def troubleshooting
    render json: {
      status: 'success',
      data: {
        title: 'Troubleshooting Guide',
        common_issues: [
          'Device connection problems',
          'Sensor calibration',
          'API authentication'
        ]
      }
    }
  end

  def support
    render json: {
      status: 'success',
      data: {
        title: 'Support',
        contact_email: 'support@spacegrow.ai'
      }
    }
  end

  def faq
    render json: {
      status: 'success',
      data: {
        title: 'Frequently Asked Questions',
        faqs: [
          {
            question: 'How do I activate a device?',
            answer: 'Use the activation token provided with your device purchase.'
          }
        ]
      }
    }
  end
end
