require 'json'
require 'pty'
require 'English'

module BoshConfigResource
  class Bosh
    attr_reader :target

    def initialize(target, ca_cert, auth, command_runner = CommandRunner.new)
      @target = target
      @ca_cert = ca_cert
      @auth = auth
      @command_runner = command_runner
    end

    def upload_release(path)
      bosh("upload release #{path} --skip-if-exists")
    end

    def update_runtime_config(manifest_path)
      bosh("update runtime-config #{manifest_path}")
    end

    def update_cloud_config(manifest_path)
      bosh("update cloud-config #{manifest_path}")
    end

    private

    attr_reader :command_runner

    def bosh(command, opts = {})
      args = ['-n', '--color', '-t', target]
      args << ['--ca-cert', @ca_cert.path] if @ca_cert.provided?
      run(
        "bosh #{args.join(' ')} #{command}",
        @auth.env,
        opts
      )
    end

    def run(command, env = {}, opts = {})
      command_runner.run(command, env, opts)
    end
  end

  class CommandRunner
    def run(command, env = {}, opts = {})
      pid = Process.spawn(env, command, { out: :err, err: :err }.merge(opts))
      Process.wait(pid)
      raise "command '#{command}' failed!" unless $CHILD_STATUS.success?
    end
  end
end
