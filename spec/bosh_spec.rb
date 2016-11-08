require 'spec_helper'

describe BoshConfigResource::CommandRunner do
  let (:command_runner) { BoshConfigResource::CommandRunner.new }

  describe '.run' do
    it 'takes a command and an environment and spanws a process' do
      expect do
        command_runner.run('sh -c "$PROG"', 'PROG' => 'true')
      end.to_not raise_error
    end

    it 'takes an options hash' do
      r, w = IO.pipe
      command_runner.run('sh -c "echo $FOO"', { 'FOO' => 'sup' }, out: w)
      expect(r.gets).to eq("sup\n")
    end

    it 'raises an exception if the command fails' do
      expect do
        command_runner.run('sh -c "$PROG"', 'PROG' => 'false')
      end.to raise_error("command 'sh -c \"$PROG\"' failed!")
    end

    it 'routes all output to stderr' do
      pid = 7223
      expect($CHILD_STATUS).to receive(:success?).and_return(true)
      expect(Process).to receive(:wait).with(pid)
      expect(Process).to receive(:spawn).with({}, 'echo "hello"', out: :err, err: :err).and_return(pid)

      command_runner.run('echo "hello"')
    end
  end
end

describe BoshConfigResource::Bosh do
  let(:target) { 'http://bosh.example.com' }
  let(:auth) { BoshConfigResource::Auth.parse('username' => username, 'password' => password) }
  let(:username) { 'bosh-userΩΩΩΩ' }
  let(:password) { 'bosh-password!#%&#(*' }
  let(:command_runner) { instance_double(BoshConfigResource::CommandRunner) }

  let(:bosh) { BoshConfigResource::Bosh.new(target, ca_cert, auth, command_runner) }
  let(:ca_cert) { BoshConfigResource::CaCert.new(nil) }

  describe '.upload_release' do
    it 'runs the command to upload a release' do
      expect(command_runner).to receive(:run).with(%(bosh -n --color -t #{target} upload release /path/to/a/release.tgz --skip-if-exists), { 'BOSH_USER' => username, 'BOSH_PASSWORD' => password }, {})

      bosh.upload_release('/path/to/a/release.tgz')
    end
  end

  describe '.update_runtime_config' do
    it 'runs the command to set runtime config' do
      expect(command_runner).to receive(:run).with(%(bosh -n --color -t #{target} update runtime-config /path/to/a/manifest.yml), { 'BOSH_USER' => username, 'BOSH_PASSWORD' => password }, {})

      bosh.update_runtime_config('/path/to/a/manifest.yml')
    end
  end

  describe '.download_runtime_config' do
    it 'runs the command to download runtime config' do
      expect(command_runner).to receive(:run).with(%(bosh -n --color -t #{target} runtime-config > /path/to/a/manifest.yml), { 'BOSH_USER' => username, 'BOSH_PASSWORD' => password }, {})

      bosh.download_runtime_config('/path/to/a/manifest.yml')
    end
  end

  context 'when ca_cert_path is provided' do
    let(:ca_cert) { BoshConfigResource::CaCert.new('fake-ca-cert-content') }
    after { ca_cert.cleanup }

    it 'passes ca_cert to bosh cli' do
      expect(command_runner).to receive(:run).with(%(bosh -n --color -t #{target} --ca-cert #{ca_cert.path} update runtime-config /path/to/a/manifest.yml), anything, anything)

      bosh.update_runtime_config('/path/to/a/manifest.yml')
    end
  end
end
