require "spec_helper"

require "digest"
require "fileutils"
require "json"
require "open3"
require "tmpdir"
require "stringio"

describe "Out Command" do
  let(:runtime_config) { instance_double(BoshConfigResource::BoshConfig, use_release: nil, shasum: "1234") }
  let(:bosh) { instance_double(BoshConfigResource::Bosh, update_runtime_config: nil, upload_release: nil, target: "bosh-target") }
  let(:response) { StringIO.new }
  let(:command) { BoshConfigResource::OutCommand.new(bosh, runtime_config, response) }

  let(:written_manifest) do
    file = Tempfile.new("bosh_manifest")
    file.write("hello world")
    file.close
    file
  end

  def touch(*paths)
    path = File.join(paths)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.touch(path)
  end

  def cp(src, *paths)
    path = File.join(paths)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.cp(src, path)
  end

  def in_dir
    Dir.mktmpdir do |working_dir|
      yield working_dir
    end
  end

  def add_default_artifacts(working_dir)
    cp "spec/fixtures/release.tgz", working_dir, "releases", "release.tgz"
    cp "spec/fixtures/release.tgz", working_dir, "releases", "other-release.tgz"
    touch working_dir, "releases", "not-release.txt"
  end

  before do
    allow(runtime_config).to receive(:write!).and_return(written_manifest)
  end

  let(:request) {
    {
      "source" => {
        "target" => "http://bosh.example.com",
        "username" => "bosh-username",
        "password" => "bosh-password",
        "type" => "runtime-config",
      },
      "params" => {
        "manifest" => "manifest/deployment.yml",
        "releases" => [
          "releases/*.tgz"
        ]
      }
    }
  }

  context "with valid inputs" do

    it "emits the version as the manifest_sha1 and target" do
      in_dir do |working_dir|
        add_default_artifacts working_dir

        command.run(working_dir, request)

        expect(JSON.parse(response.string)["version"]).to eq({
          "manifest_sha1" => runtime_config.shasum,
          "target" => "bosh-target",
        })
      end
    end

    # it "emits the release versions in the metadata" do
    #   in_dir do |working_dir|
    #     add_default_artifacts working_dir
    #
    #     command.run(working_dir, request)
    #
    #     expect(JSON.parse(response.string)["metadata"]).to eq([
    #       {"name" => "release", "value" => "concourse v0.43.0"},
    #       {"name" => "release", "value" => "concourse v0.43.0"}
    #     ])
    #   end
    # end

    # it "uploads matching releases to the director" do
    #   in_dir do |working_dir|
    #     add_default_artifacts working_dir
    #
    #     expect(bosh).to receive(:upload_release).
    #       with(File.join(working_dir, "releases", "release.tgz"))
    #     expect(bosh).to receive(:upload_release).
    #       with(File.join(working_dir, "releases", "other-release.tgz"))
    #
    #     command.run(working_dir, request)
    #   end
    # end

    # it "handles overlapping release globs by removing duplication" do
    #   request.fetch("params").store("releases", [
    #     "releases/*.tgz",
    #     "releases/*.tgz"
    #   ])
    #
    #   in_dir do |working_dir|
    #     add_default_artifacts working_dir
    #
    #     expect(bosh).to receive(:upload_release).exactly(2).times
    #
    #     command.run(working_dir, request)
    #   end
    # end

    it "generates a new manifest (with locked down versions and a defaulted director uuid) and deploys it" do
      in_dir do |working_dir|
        add_default_artifacts working_dir

        expect(runtime_config).to receive(:use_release)

        expect(bosh).to receive(:update_runtime_config).with(written_manifest.path)

        command.run(working_dir, request)
      end
    end
  end

  context "with invalid inputs" do
    it "requires a manifest" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "username" => "bosh-username",
              "password" => "bosh-password",
              "type" => "runtime-config",
            },
            "params" => {
              "releases" => []
            }
          })
        end.to raise_error /params must include 'manifest'/
      end
    end

    describe "release globs" do
      it "errors if a glob resolves to an empty list of files" do
        in_dir do |working_dir|
          touch working_dir, "releases", "release.rtf"

          expect do
            command.run(working_dir, request)
          end.to raise_error "glob 'releases/*.tgz' matched no files"
        end
      end
    end
  end
end
