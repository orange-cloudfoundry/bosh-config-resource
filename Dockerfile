FROM concourse/buildroot:ruby

ADD gems /tmp/gems

RUN gem install /tmp/gems/*.gem --no-document && \
    wget https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-2.0.1-linux-amd64 -O bosh-cli && \
    chmod +x bosh-cli && \
    mv bosh-cli /usr/local/bin/bosh


ADD . /tmp/resource-gem

RUN cd /tmp/resource-gem && \
    gem build *.gemspec && gem install *.gem --no-document && \
    mkdir -p /opt/resource && \
    ln -s $(which bcr_check) /opt/resource/check && \
    ln -s $(which bcr_in) /opt/resource/in && \
    ln -s $(which bcr_out) /opt/resource/out
