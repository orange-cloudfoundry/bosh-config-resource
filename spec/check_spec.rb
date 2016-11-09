require 'spec_helper'

require 'json'
require 'open3'

describe 'Check Command' do
  let(:bosh) { instance_double(BoshConfigResource::Bosh) }
  let(:writer) { StringIO.new }
  let(:request) do
    {
      'source' => {
        'username' => 'bosh-username',
        'password' => 'bosh-password',
        'type' => 'runtime-config'
      },
      'version' => {
        'manifest_sha1' => 'some-sha'
      }
    }
  end

  let(:manifest_from_bosh) do
    <<EOF
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
  end

  let(:command) { BoshConfigResource::CheckCommand.new(bosh, writer) }

  context 'whenever' do
    it "fails because it's not implemented" do
      expect { command.run(request) }.to raise_error('not implemented')
    end
  end
end
