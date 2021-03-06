module Memoizable
  extend ActiveSupport::Concern

  included do
    def memoized(options = {}, &block)
      loc = caller_locations(1, 1).first
      @_memoized ||= {}

      if @_memoized["#{loc.path}:#{loc.lineno}:nil"]
        return nil
      end

      @_memoized["#{loc.path}:#{loc.lineno}"] ||= -> {
        ret = block.call

        if ret.nil?
          @_memoized["#{loc.path}:#{loc.lineno}:nil"] = true
        end

        options.fetch(:freeze, false) ? ret.freeze : ret
      }.call
    end

    def clear_memoized
      @_memoized = {}
    end
  end
end
