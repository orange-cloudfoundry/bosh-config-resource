require 'tempfile'
require 'yaml'

module BoshConfigResource
  class BoshConfig
    def initialize(path)
      @manifest = YAML.load_file(path)
    end

    def use_release(release)
      manifest.fetch('releases')
              .find(no_release_found(release.name)) { |r| r.fetch('name') == release.name }
              .store('version', release.version)
    end

    def write!
      file = Tempfile.new('bosh_manifest')

      File.write(file.path, YAML.dump(manifest))

      file
    end

    def shasum
      sum = lambda do |o, digest|
        if o.respond_to?(:keys)
          o.sort.each do |k, v|
            digest << k.to_s
            sum[v, digest]
          end
        elsif o.respond_to?(:each)
          o.each { |x| sum[x, digest] }
        else
          digest << o.to_s
        end
      end

      d = Digest::SHA1.new
      sum[manifest, d]

      d.hexdigest
    end

    private

    attr_reader :manifest

    def no_release_found(name)
      proc { raise "#{name} can not be found in manifest releases" }
    end
  end
end
