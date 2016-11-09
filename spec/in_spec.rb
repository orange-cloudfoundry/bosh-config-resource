require 'spec_helper'

require 'json'
require 'stringio'
require 'time'

describe 'In Command' do
  let(:response) { StringIO.new }
  let(:bosh) { instance_double(BoshConfigResource::Bosh, target: '') }
  let(:command) { BoshConfigResource::InCommand.new(bosh, response) }

  def run_command
    Dir.mktmpdir do |working_dir|
      command.run(working_dir, request)
      response.rewind
    end
  end

  context 'whenever' do
    let(:request) do
      {
        'source' => {
          'target' => 'http://bosh.example.com',
          'username' => 'bosh-username',
          'password' => 'bosh-password',
          'type' => 'runtime-config'
        },
        'version' => {
          'manifest_sha1' => 'abcdef'
        }
      }
    end

    it "fails because it's not implemented" do
      expect { run_command }.to raise_error('not implemented')
    end
  end
end
