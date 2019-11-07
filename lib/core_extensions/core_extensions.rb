# frozen_string_literal: true

module CoreExtensions
  module Object
    # Object extension to include .present? and .not_present? method
    module PresenceCheck
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
