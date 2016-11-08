require "spec_helper"

require "json"
require "stringio"
require "time"

describe "In Command" do
  let(:response) { StringIO.new }
  let(:bosh) { instance_double(BoshConfigResource::Bosh, download_runtime_config: nil, target: "") }
  let(:command) { BoshConfigResource::InCommand.new(bosh, response) }

  def run_command
    Dir.mktmpdir do |working_dir|
      command.run(working_dir, request)
      response.rewind
    end
  end

  context "when the version is given on STDIN" do
    let(:request) {
      {
        "source" => {
          "username" => "bosh-username",
          "password" => "bosh-password",
          "type" => "runtime_config",
        },
        "version" => {
          "manifest_sha1" => "abcdef"
        }
      }
    }

    it "outputs the version that it was given" do
      run_command

      expected = {
        "version" => {
          "manifest_sha1" => "abcdef"
        }
      }

      output = JSON.parse(response.read)
      expect(output).to eq(expected)
    end

    context "when the source has a target" do
      before do
        allow(bosh).to receive(:target).and_return("bosh-target")
      end

      it "downloads the manifest" do
        Dir.mktmpdir do |working_dir|
          expect(bosh).to receive(:download_runtime_config).with(File.join(working_dir, "manifest.yml"))
          command.run(working_dir, request)
        end
      end

      it "writes the target to a file called target" do
        Dir.mktmpdir do |working_dir|
          expect(bosh).to receive(:download_runtime_config).with(File.join(working_dir, "manifest.yml"))
          command.run(working_dir, request)

          path = File.join(working_dir, "target")
          expect(File.exists?(path)).to be_truthy

          expect(File.read(path)).to eq("bosh-target")
        end
      end
    end

    context "when the source does not have a target" do
      before do
        allow(bosh).to receive(:target).and_return("")
      end

      it "does not try to download the manifest" do
        expect(bosh).not_to receive(:download_runtime_config)
        run_command
      end

      it "outputs the version that it was given" do
        run_command

        expected = {
          "version" => {
            "manifest_sha1" => "abcdef"
          }
        }

        output = JSON.parse(response.read)
        expect(output).to eq(expected)
      end
    end
  end

  context "when the version is not given on STDIN" do
    let(:request) {
      {
        "source" => {
          "target" => "http://bosh.example.com",
          "username" => "bosh-username",
          "password" => "bosh-password",
          "type" => "runtime-config",
        }
      }
    }

    it "fails" do
      expect { run_command }.to raise_error("no version specified")
    end
  end
end
