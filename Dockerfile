FROM heroku/cedar:14

ENV GHCVER 7.8.4
ENV CABALVER 1.18

RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common \
  && add-apt-repository -y ppa:hvr/ghc \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    cabal-install-$CABALVER \
    ghc-$GHCVER \
  && rm -rf /var/lib/apt/lists/*

ENV PATH /opt/ghc/$GHCVER/bin:/opt/cabal/$CABALVER/bin:$PATH

## Default config
ENV CABALCONFIG /root/.cabal/config

RUN echo "===> Installing stackage LTS-2.9" \
  && cabal update \
  && curl --silent 'http://www.stackage.org/snapshot/lts-2.9/cabal.config?global=true' >> /tmp/stackage.cabal.config \
  && echo "0e8774a5f4b29bbc43be2277b1d25acf96f4c94a5d1f90182d17a89072ab7c7e  /tmp/stackage.cabal.config" | sha256sum -c \
  && cat /tmp/stackage.cabal.config >> $CABALCONFIG \
  && rm -f /tmp/stackage.cabal.config \
  && echo "library-profiling: False" >> $CABALCONFIG \
  && echo "documentation: False" >> $CABALCONFIG

RUN gpg --recv-key --keyserver keyserver.ubuntu.com D6CF60FD
# Changing trust level to 4 = marginally trust
RUN echo E595AD4214AFA6BB15520B23E40D74D6D6CF60FD:4: | \
    gpg --import-ownertrust

# Install stackage
RUN cabal install stackage
ENV PATH /root/.cabal/bin:$PATH

WORKDIR /build
CMD stk install --only-dependencies && cabal build
