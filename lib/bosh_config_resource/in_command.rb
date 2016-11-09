require 'json'
require 'time'

module BoshConfigResource
  class InCommand
    def initialize(bosh, writer = STDOUT)
      @writer = writer
      @bosh = bosh
    end

    def run(_working_dir, _request)
      raise 'not implemented'
    end

    private

    attr_reader :writer, :bosh
  end
end
