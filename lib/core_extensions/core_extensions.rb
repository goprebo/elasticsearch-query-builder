# frozen_string_literal: true

module CoreExtensions
  module Object
    module PresenceCheck
      # Converts in place all the keys to string
      #
      # @return [Hash]
      def present?
        !not_present?
      end

      def not_present?
        to_s.empty?
      end

      ::Object.include self
    end
  end
end
