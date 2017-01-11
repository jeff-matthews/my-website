module Nanoc::Int
  # @private
  class ActionProvider
    extend DDPlugin::Plugin

    def self.for(_site)
      raise NotImplementedError
    end

    def rep_names_for(_item)
      raise NotImplementedError
    end

    def memory_for(_rep)
      raise NotImplementedError
    end

    def snapshots_defs_for(_rep)
      raise NotImplementedError
    end

    def paths_for(rep)
      memory_for(rep).paths
    end
  end
end
