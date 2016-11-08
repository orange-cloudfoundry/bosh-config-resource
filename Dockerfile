FROM concourse/buildroot:ruby

ADD gems /tmp/gems

RUN gem install /tmp/gems/*.gem --no-document && \
    gem install bosh_cli -v 1.3262.4.0 --no-document

ADD . /tmp/resource-gem

RUN cd /tmp/resource-gem && \
    gem build *.gemspec && gem install *.gem --no-document && \
    mkdir -p /opt/resource && \
    ln -s $(which bcr_check) /opt/resource/check && \
    ln -s $(which bcr_in) /opt/resource/in && \
    ln -s $(which bcr_out) /opt/resource/out
