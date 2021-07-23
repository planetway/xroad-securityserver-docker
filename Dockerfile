FROM ubuntu:bionic
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
        ca-certificates gnupg supervisor net-tools iproute2 locales \
        setpriv openjdk-8-jre-headless rlwrap ca-certificates-java \
        crudini adduser expect nginx-light curl rsyslog authbind gettext-base lsb-release awscli jq \
    && echo "LC_ALL=en_US.UTF-8" >>/etc/environment \
    && locale-gen en_US.UTF-8 \
    && adduser --quiet --system --uid 998 --home /var/lib/postgresql --no-create-home --shell /bin/bash --group postgres \
    && adduser --quiet --system --uid 999 --home /var/lib/xroad --no-create-home --shell /bin/bash --group xroad \
    && useradd -m xrd -s /usr/sbin/nologin -p '$6$JeOzaeWnLAQSUVuO$GOJ0wUKSVQnOR4I2JgZxdKr.kMO.YGS21SGaAshaYhayv8kSV9WuIFCZHTGAX8WRRTB/2ojuLnJg4kMoyzpcu1' \
    && echo "xroad-proxy xroad-common/username string xrd" | debconf-set-selections \
    && apt-get -qq install postgresql postgresql-contrib \
    && apt-get -qq clean

ARG PX_REPOSITORY_URL=https://deb.conneqt.net/
RUN echo "deb [arch=amd64] $PX_REPOSITORY_URL `lsb_release -cs` non-free" > /etc/apt/sources.list.d/conneqt.list && \
    echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu `lsb_release -cs` main" >> /etc/apt/sources.list.d/conneqt.list && \
    echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu `lsb_release -cs` main" >> /etc/apt/sources.list.d/conneqt.list

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 731E775DF768EF67 && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 00A6F0A3C300EE8C && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EB9B1D8886F44E2A

ARG PX_CANDIDATE=latest
RUN pg_ctlcluster 10 main start \
    && apt-get update \
    && [ "$PX_CANDIDATE" = "latest" ] && export PX_CANDIDATE=`apt policy xroad-securityserver-conneqt 2>/dev/null | grep Candidate: | cut -c 14-` \
    ; apt-get -y install \
        xroad-securityserver-conneqt="$PX_CANDIDATE.bionic" \
        xroad-securityserver="$PX_CANDIDATE.bionic" \
        xroad-addon-opmonitoring="$PX_CANDIDATE.bionic" \
        xroad-addon-hwtokens="$PX_CANDIDATE.bionic" \
        xroad-proxy="$PX_CANDIDATE.bionic" \
        xroad-proxy-ui-api="$PX_CANDIDATE.bionic" \
        xroad-addon-metaservices="$PX_CANDIDATE.bionic" \
        xroad-addon-messagelog="$PX_CANDIDATE.bionic" \
        xroad-addon-proxymonitor="$PX_CANDIDATE.bionic" \
        xroad-addon-wsdlvalidator="$PX_CANDIDATE.bionic" \
        xroad-confclient="$PX_CANDIDATE.bionic" \
        xroad-signer="$PX_CANDIDATE.bionic" \
        xroad-base="$PX_CANDIDATE.bionic" \
        xroad-opmonitor="$PX_CANDIDATE.bionic" \
        xroad-monitor="$PX_CANDIDATE.bionic" \
        xroad-autologin="$PX_CANDIDATE.bionic" \
    && apt-get -qq clean \
    && pg_ctlcluster 10 main stop

# Remove the default admin UI user
RUN userdel -r xrd
# Remove generated internal and nginx keys and certificates
RUN rm /etc/xroad/ssl/*.crt /etc/xroad/ssl/*.key /etc/xroad/ssl/*.p12

# Install envsubst with default value support
RUN curl -L https://github.com/a8m/envsubst/releases/download/v1.1.0/envsubst-Linux-x86_64 -o envsubst \
    && echo '10f957091859c04f62eeffbc6b23a29dc9c8c79721672c158f04a813144f4a12 *envsubst' | sha256sum -c - \
    && chmod +x envsubst \
    && mv envsubst /usr/local/bin

ADD files /files/

# Install files into correct places.
# Later more files will be copied in entrypoint.sh
RUN cp /files/logback/*.xml    /etc/xroad/conf.d/
RUN cp /files/logback/addons/* /etc/xroad/conf.d/addons/

EXPOSE 80 443 2080 4000 5500 5577 5588 8083

# max 5min
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=10 \
  CMD curl -f http://localhost:5588/ || exit 1

ENTRYPOINT ["/files/entrypoint.sh"]
CMD ["/files/cmd.sh"]
