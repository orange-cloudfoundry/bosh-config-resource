require "spec_helper"

require "json"
require "open3"

describe "Check Command" do
  let(:bosh) { instance_double(BoshConfigResource::Bosh, download_runtime_config: nil) }
  let(:writer) { StringIO.new }
  let(:request) {
    {
      "source" => {
        "username" => "bosh-username",
        "password" => "bosh-password",
        "type" => "runtime-config",
      },
      "version" => {
        "manifest_sha1" => "some-sha"
      }
    }
  }

  let(:manifest_from_bosh) { <<EOF
---
qux:
  corge: grault
wiff:
- a
- b
- c
foo:
  bar: baz
EOF
  }

  let(:command) { BoshConfigResource::CheckCommand.new(bosh, writer) }

  context "whenever" do
    it "fails because it's not implemented" do
      expect{command.run(request)}.to raise_error("not implemented")

    end
  end

=begin
  context "when the source does have a target" do
    before do
      allow(bosh).to receive(:target).and_return("bosh-target")
    end

    it "downloads the config" do
      expect(bosh).to receive(:download_runtime_config).with(anything) do |manifest_path|
        File.open(manifest_path, 'w+') do |f|
          f.write(manifest_from_bosh)
        end
      end
      command.run(request)
    end

    context "when the provided version differs from the downloaded manifest's sha" do
      before do
        request["version"] = {
          "manifest_sha1" => "different-sha"
        }
      end

      it "outputs the version as the sha of the values of the sorted, parsed manifest" do
        allow(bosh).to receive(:download_runtime_config) do |path|
          File.open(path, 'w+') do |f|
            f.write(manifest_from_bosh)
          end
        end

        command.run(request)

        d = Digest::SHA1.new
        d << 'foo'      # foo:
        d << 'bar'      #   bar: baz
        d << 'baz'      #
        d << 'qux'      # qux:
        d << 'corge'    #   corge: grault
        d << 'grault'   #
        d << 'wiff'     # wiff:
        d << 'a'        # - a
        d << 'b'        # - b
        d << 'c'        # - c

        expected = [ {"manifest_sha1" => d.hexdigest} ]

        writer.rewind
        output = JSON.parse(writer.read)
        expect(output).to eq(expected)
      end
    end

    context "when the provided version is the same as the downloaded manifest's sha" do
      before do
        request["version"] = {
          "manifest_sha1" => "e530a7b5a47f1887b2e48a45c1895cb3f8eb032f"
        }
      end

      it "outputs an empty array" do
        allow(bosh).to receive(:download_runtime_config) do |path|
          File.open(path, 'w+') do |f|
            f.write(manifest_from_bosh)
          end
        end

        command.run(request)

        writer.rewind
        output = JSON.parse(writer.read)
        expect(output).to eq([])
      end
    end
  end

  context "when the source does not have a target" do
    before do
      allow(bosh).to receive(:target).and_return("")
    end

    it "does not try to download the manifest" do
      expect(bosh).not_to receive(:download_runtime_config)
      command.run(request)
    end

    it "outputs an empty array of versions" do
      command.run(request)

      writer.rewind
      output = JSON.parse(writer.read)
      expect(output).to eq([])
    end
  end
=end
end
