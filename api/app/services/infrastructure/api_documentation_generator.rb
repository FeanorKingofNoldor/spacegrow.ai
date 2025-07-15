module Infrastructure 
  class ApiDocumentationGenerator < ApplicationService
    def self.generate
      {
        openapi: '3.0.0',
        info: {
          title: 'SpaceXGrow API',
          version: '1.0.0'
        },
        paths: generate_paths,
        components: {
          schemas: generate_schemas
        }
      }
    end
  
    private
  
    def self.generate_paths
      {
        '/api/v1/sensor_data': {
          post: {
            summary: 'Submit sensor readings',
            description: 'Submit readings for device sensors',
            requestBody: {
              content: {
                'application/json': {
                  schema: {
                    oneOf: DeviceType.all.map { |dt| reference_for(dt) }
                  }
                }
              }
            }
          }
        }
      }
    end
  
    def self.generate_schemas
      DeviceType.all.each_with_object({}) do |device_type, schemas|
        schemas[schema_name_for(device_type)] = {
          type: 'object',
          required: required_fields_for(device_type),
          properties: properties_for(device_type),
          example: device_type.example_payload
        }
      end
    end
  
    # Helper methods for schema generation
    def self.schema_name_for(device_type)
      device_type.name.parameterize.underscore + '_payload'
    end
  
    def self.reference_for(device_type)
      { '$ref': "#/components/schemas/#{schema_name_for(device_type)}" }
    end
  
    def self.required_fields_for(device_type)
      ['timestamp'] + device_type.configuration['supported_sensor_types']
        .select { |_, config| config['required'] }
        .map { |_, config| config['payload_key'] }
    end
  
    def self.properties_for(device_type)
      props = {
        timestamp: {
          type: 'integer',
          description: 'Unix timestamp of the readings'
        }
      }
  
      device_type.configuration['supported_sensor_types'].each do |name, config|
        props[config['payload_key']] = {
          type: 'number',
          description: "Reading from #{name} (#{config['unit']})"
        }
      end
  
      props
    end
  end
end