FROM registry.access.redhat.com/ubi9/ubi

# Add certs for trusted connections to internal services.
RUN curl -k https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem --output /etc/pki/ca-trust/source/anchors/Current-IT-Root-CAs.pem \
    && update-ca-trust

# Add sources
COPY . /usr/local/src/manifest-api/
COPY conf/gunicorn.conf /etc/manifest-api-gunicorn.conf

WORKDIR /usr/local/src/manifest-api

    # install required packages.
RUN dnf install -y --disableplugin=subscription-manager python3 python3-pip \
    python3-devel gcc ca-certificates git openssl-devel krb5-devel \
    # make a venv where the app and its deps will live
    && python3 -m venv /venv \
    # ensure pip is up-to-date before doing more work, and ensure
    # wheel is installed so that some deps don't need compilation
    && /venv/bin/pip install --upgrade pip wheel \
    # install source. Upgrade cryptography for security.
    && /venv/bin/pip install --upgrade . cryptography \
    # Clean up
    && /venv/bin/pip uninstall -y setuptools wheel \
    && dnf -y erase rpm-build python3-pip perl gcc git \
    && dnf -y autoremove && dnf clean all \
    && rm -rf /var/yum/cache && rm -rf /usr/local/src/manifest-api

# Run as a non-root user
RUN adduser manifest-api
USER manifest-api

#Set env var to force the cdn utils library to open files remotely
ENV CDN_UTILS_FORCE_FALLBACK_LOAD=1

# Ensure requests library in venv can find system CA bundle
ENV REQUESTS_CA_BUNDLE=/etc/pki/tls/certs/ca-bundle.crt

# This port matches the gunicorn config file
EXPOSE 8080

