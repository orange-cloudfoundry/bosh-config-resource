require 'spec_helper'

require 'digest'
require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'
require 'stringio'

describe 'Out Command' do
  let(:runtime_config) { instance_double(BoshConfigResource::BoshConfig, use_release: nil, shasum: '1234') }
  let(:cloud_config) { instance_double(BoshConfigResource::BoshConfig, shasum: '5678') }
  let(:bosh) { instance_double(BoshConfigResource::Bosh, update_runtime_config: nil, update_cloud_config: nil, upload_release: nil, target: 'bosh-target') }
  let(:response) { StringIO.new }
  let(:command) { BoshConfigResource::OutCommand.new(bosh, runtime_config, response) }
  let(:command_cc) { BoshConfigResource::OutCommand.new(bosh, cloud_config, response) }

  let(:written_manifest) do
    file = Tempfile.new('bosh_manifest')
    file.write('hello world')
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
    cp 'spec/fixtures/release.tgz', working_dir, 'releases', 'release.tgz'
    cp 'spec/fixtures/release.tgz', working_dir, 'releases', 'other-release.tgz'
    touch working_dir, 'releases', 'not-release.txt'
  end

  before do
    allow(runtime_config).to receive(:write!).and_return(written_manifest)
    allow(cloud_config).to receive(:write!).and_return(written_manifest)
  end

  context "runtime-config" do

    let(:request) do
      {
          'source' => {
              'target' => 'http://bosh.example.com',
              'username' => 'bosh-username',
              'password' => 'bosh-password',
              'type' => 'runtime-config'
          },
          'params' => {
              'manifest' => 'manifest/deployment.yml',
              'releases' => [
                  'releases/*.tgz'
              ]
          }
      }
    end

    context 'with valid inputs' do
      it 'emits the version as the manifest_sha1 and target' do
        in_dir do |working_dir|
          add_default_artifacts working_dir

          command.run(working_dir, request)

          expect(JSON.parse(response.string)['version']).to eq('manifest_sha1' => runtime_config.shasum,
                                                               'target' => 'bosh-target')
        end
      end

      it 'generates a new manifest (with locked down versions and a defaulted director uuid) and deploys it' do
        in_dir do |working_dir|
          add_default_artifacts working_dir

          expect(runtime_config).to receive(:use_release)

          expect(bosh).to receive(:update_runtime_config).with(written_manifest.path)

          command.run(working_dir, request)
        end
      end
    end

    context 'with invalid inputs' do
      it 'requires a manifest' do
        in_dir do |working_dir|
          expect do
            command.run(working_dir, 'source' => {
                'target' => 'http://bosh.example.com',
                'username' => 'bosh-username',
                'password' => 'bosh-password',
                'type' => 'runtime-config'
            },
                        'params' => {
                            'releases' => []
                        })
          end.to raise_error /params must include 'manifest'/
        end
      end

      describe 'release globs' do
        it 'errors if a glob resolves to an empty list of files' do
          in_dir do |working_dir|
            touch working_dir, 'releases', 'release.rtf'

            expect do
              command.run(working_dir, request)
            end.to raise_error "glob 'releases/*.tgz' matched no files"
          end
        end
      end
    end

  end

  context "cloud-config" do

    let(:request) do
      {
          'source' => {
              'target' => 'http://bosh.example.com',
              'username' => 'bosh-username',
              'password' => 'bosh-password',
              'type' => 'cloud-config'
          },
          'params' => {
              'manifest' => 'manifest/cloud-config.yml',
              'releases' => [
                  'releases/*.tgz'
              ]
          }
      }
    end

    context 'with valid inputs' do
      it 'emits the version as the manifest_sha1 and target' do
        in_dir do |working_dir|
          add_default_artifacts working_dir

          command_cc.run(working_dir, request)

          expect(JSON.parse(response.string)['version']).to eq('manifest_sha1' => cloud_config.shasum,
                                                               'target' => 'bosh-target')
        end
      end

      it 'generates a new manifest (with locked down versions and a defaulted director uuid) and deploys it' do
        in_dir do |working_dir|
          add_default_artifacts working_dir

          expect(bosh).to receive(:update_cloud_config).with(written_manifest.path)

          command_cc.run(working_dir, request)
        end
      end
    end

    context 'with invalid inputs' do
      it 'requires a manifest' do
        in_dir do |working_dir|
          expect do
            command_cc.run(working_dir, 'source' => {
                'target' => 'http://bosh.example.com',
                'username' => 'bosh-username',
                'password' => 'bosh-password',
                'type' => 'cloud-config'
              },
              'params' => {}
            )
          end.to raise_error /params must include 'manifest'/
        end
      end
    end

  end

  context "badness-config" do

    let(:request) do
      {
          'source' => {
              'target' => 'http://bosh.example.com',
              'username' => 'bosh-username',
              'password' => 'bosh-password',
              'type' => 'badness'
          },
          'params' => {
              'manifest' => 'manifest/cloud-config.yml',
              'releases' => [
                  'releases/*.tgz'
              ]
          }
      }
    end

    context 'with invalid type' do
      it 'fails' do
        in_dir do |working_dir|
          add_default_artifacts working_dir

          expect{ command.run(working_dir, request) }.to raise_error "'source.type' must equal 'runtime-config' or 'cloud-config'"
        end
      end
    end
  end
end
