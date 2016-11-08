require "spec_helper"

require "yaml"

describe BoshConfigResource::BoshConfig do
  let(:runtime_config) { BoshConfigResource::BoshConfig.new("spec/fixtures/manifest.yml") }
  # let(:cloud_config) { BoshConfigResource::BoshConfig.new("spec/fixtures/bosh_2_manifest.yml") }

  let(:resulting_runtime_config) { YAML.load_file(runtime_config.write!) }
  # let(:resulting_cloud_config) { YAML.load_file(cloud_config.write!) }

  it "can replace the releases used in a manifest" do
    concourse = instance_double(BoshConfigResource::BoshRelease, name: "concourse", version: "1234")
    garden = instance_double(BoshConfigResource::BoshRelease, name: "garden-linux", version: "9876")

    runtime_config.use_release(concourse)
    runtime_config.use_release(garden)

    releases = resulting_runtime_config.fetch("releases")

    expect(releases).to match_array [
      {
        "name" => "concourse",
        "version" => "1234",
      },
      {
        "name" => "garden-linux",
        "version" => "9876",
      }
    ]
  end

  it "errors if a release is called which isn't defined in the manifest releases list" do
    unfindable_release = double(name: "wrong_name", version: 0)

    expect do
      runtime_config.use_release(unfindable_release)
    end.to raise_error /#{unfindable_release.name} can not be found in manifest releases/
  end

  describe "#shasum" do
    it "outputs the version as the sha of the values of the sorted, parsed manifest" do
      # actual = manifest.shasum
      #
      # d = Digest::SHA1.new
      #
      # d << 'name'                                             # name: concourse
      # d << 'concourse'                                        #
      # d << 'releases'                                         # releases:
      # d << 'name'                                             #   - name: concourse
      # d << 'concourse'                                        #
      # d << 'version'                                          #     version: latest
      # d << 'latest'                                           #
      # d << 'name'                                             #   - name: garden-linux
      # d << 'garden-linux'                                     #
      # d << 'version'                                          #     version: latest
      # d << 'latest'                                           #
      # d << 'resource_pools'                                   # resource_pools:
      # d << 'name'                                             #   - name: fast
      # d << 'fast'                                             #
      # d << 'stemcell'                                         #     stemcell:
      # d << 'name'                                             #       name: bosh-warden-boshlite-ubuntu-trusty-go_agent
      # d << 'bosh-warden-boshlite-ubuntu-trusty-go_agent'      #
      # d << 'version'                                          #       version: latest
      # d << 'latest'                                           #
      # d << 'name'                                             #   - name: other-fast
      # d << 'other-fast'                                       #
      # d << 'stemcell'                                         #     stemcell:
      # d << 'name'                                             #       name: bosh-warden-boshlite-ubuntu-trusty-go_agent
      # d << 'bosh-warden-boshlite-ubuntu-trusty-go_agent'      #
      # d << 'version'                                          #       version: latest
      # d << 'latest'                                           #
      # d << 'name'                                             #   - name: slow
      # d << 'slow'                                             #
      # d << 'stemcell'                                         #     stemcell:
      # d << 'name'                                             #       name: bosh-warden-boshlite-ubuntu-trusty-ruby_agent
      # d << 'bosh-warden-boshlite-ubuntu-trusty-ruby_agent'    #
      # d << 'version'                                          #       version: latest
      # d << 'latest'                                           #
      # d << 'name'                                             #   - name: non-latest
      # d << 'non-latest'                                       #
      # d << 'stemcell'                                         #     stemcell:
      # d << 'name'                                             #       name: bosh-warden-boshlite-ubuntu-trusty-ruby_agent
      # d << 'bosh-warden-boshlite-ubuntu-trusty-ruby_agent'    #
      # d << 'version'                                          #       version: 1000
      # d << '1000'                                             #
      #
      # expect(actual).to eq(d.hexdigest)
    end
  end
end
