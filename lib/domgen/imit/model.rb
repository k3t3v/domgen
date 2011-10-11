module Domgen
  module Imit

    class ImitationAttribute < Domgen.ParentedElement(:attribute)

      def field_name
        attribute.name
      end

      def transport_primitive?
        attribute.reference? ? (!attribute.nullable? && (attribute.referenced_entity.primary_key.attribute_type == :integer || attribute.referenced_entity.primary_key.attribute_type == :boolean)) : primitive?
      end

      def transport_name
        attribute.reference? ? attribute.referencing_link_name : field_name
      end

      def transport_java_type
        attribute.reference? ? attribute.referenced_entity.primary_key.imit.java_type : attribute.imit.java_type
      end

      def transport_attribute_type
        attribute.reference? ? attribute.referenced_entity.primary_key.attribute_type : attribute.attribute_type
      end

      attr_writer :client_side

      def client_side?
        @client_side.nil? ? attribute.entity.imit.client_side? : @client_side
      end

      include Domgen::Java::JavaCharacteristic

      protected

      def characteristic
        attribute
      end

      def entity_to_classname(entity)
        entity.imit.qualified_imitation_name
      end

      def enumeration_to_classname(enumeration)
        enumeration.imit.qualified_enumeration_name
      end
    end

    class ImitationClass < Domgen.ParentedElement(:entity)

      attr_accessor :transport_id

      def imitation_name
        entity.name
      end

      def qualified_imitation_name
        "#{entity.data_module.imit.imitation_package}.#{imitation_name}"
      end

      attr_writer :client_side

      def client_side?
        @client_side.nil? ? entity.data_module.imit.client_side? : @client_side
      end
    end

    class ImitationEnumeration < Domgen.ParentedElement(:enumeration)
      def enumeration_name
        "#{enumeration.name}"
      end

      def qualified_enumeration_name
        "#{enumeration.data_module.imit.imitation_package}.#{enumeration.name}"
      end
    end

    class ImitationModule < Domgen.ParentedElement(:data_module)
      attr_writer :imitation_package

      def imitation_package
        @imitation_package || "#{data_module.repository.imit.imitation_package}.#{Domgen::Naming.underscore(data_module.name)}"
      end

      def json_mapper_name
        "#{data_module.name}JsonMapper"
      end

      def qualified_json_mapper_name
        "#{imitation_package}.#{json_mapper_name}"
      end

      def rpc_mapper_name
        "#{data_module.name}RpcMapper"
      end

      def qualified_rpc_mapper_name
        "#{imitation_package}.#{rpc_mapper_name}"
      end

      def updater_name
        "#{data_module.name}Updater"
      end

      def qualified_updater_name
        "#{imitation_package}.#{updater_name}"
      end

      attr_writer :client_side

      def client_side?
        @client_side.nil? ? !@imitation_package.nil? : @client_side
      end

      def client_side_entities
        data_module.entities.select { |entity| entity.imit.client_side?  }
      end
    end

    class ImitationApplication < Domgen.ParentedElement(:repository)
      attr_writer :imitation_package

      def imitation_package
        @imitation_package || Domgen::Naming.underscore(repository.name)
      end

      def json_mapper_name
        "#{repository.name}JsonMapper"
      end

      def qualified_json_mapper_name
        "#{imitation_package}.#{json_mapper_name}"
      end

      def rpc_mapper_name
        "#{repository.name}RpcMapper"
      end

      def qualified_rpc_mapper_name
        "#{imitation_package}.#{rpc_mapper_name}"
      end

      def client_side_data_modules
        repository.data_modules.select{|data_module| data_module.imit.client_side? }
      end

      def client_side_entities
        client_side_data_modules.collect{ |data_module| data_module.imit.client_side_entities }.flatten
      end

      def concrete_client_side_entities
        client_side_entities.select{|entity| !entity.abstract?}
      end

      def post_verify
        concrete_client_side_entities.each_with_index {|entity, index| entity.imit.transport_id = index}
      end
    end
  end

  FacetManager.define_facet(:imit,
                            EnumerationSet => Domgen::Imit::ImitationEnumeration,
                            Attribute => Domgen::Imit::ImitationAttribute,
                            Entity => Domgen::Imit::ImitationClass,
                            DataModule => Domgen::Imit::ImitationModule,
                            Repository => Domgen::Imit::ImitationApplication)
end