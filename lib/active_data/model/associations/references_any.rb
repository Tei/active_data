module ActiveData
  module Model
    module Associations
      class ReferencesAny < Base
        def scope(source = read_source)
          reflection.persistence_adapter.scope(owner, source)
        end

      private

        def build_object(attributes)
          reflection.persistence_adapter.build(attributes)
        end

        def persist_object(object, **options)
          reflection.persistence_adapter.persist(object, **options)
        end
      end
    end
  end
end
