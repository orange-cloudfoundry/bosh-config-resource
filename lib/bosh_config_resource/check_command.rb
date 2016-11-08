require 'json'

module BoshConfigResource
  class CheckCommand
    def initialize(bosh, writer = STDOUT)
      @bosh = bosh
      @writer = writer
    end

    def run(_request)
      raise 'not implemented'
    end

    private

    attr_reader :writer, :bosh
  end
end
