FROM blueogive/mro-docker:20190710

ENV RSTUDIO_VERSION=1.2.1335 \
    S6_VERSION=v1.22.1.0 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    PANDOC_TEMPLATES_VERSION=2.7.2 \
    PATH=/usr/lib/rstudio-server/bin:$PATH
ENV RSTUDIO_URL="https://download2.rstudio.org/server/bionic/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb"

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  gdebi-core \
  libapparmor1 \
  libclang-dev \
  lsb-release \
  psmisc \
  sudo \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/ \
  && wget -q $RSTUDIO_URL \
  && dpkg -i rstudio-server-*-amd64.deb \
  && rm rstudio-server-*-amd64.deb

## Install pandoc-templates.
RUN mkdir -p /opt/pandoc/templates \
  && cd /opt/pandoc/templates \
  && wget -q https://github.com/jgm/pandoc-templates/archive/${PANDOC_TEMPLATES_VERSION}.tar.gz \
  && tar xzf ${PANDOC_TEMPLATES_VERSION}.tar.gz \
  && rm ${PANDOC_TEMPLATES_VERSION}.tar.gz \
  && mkdir /root/.pandoc \
  && ln -s /opt/pandoc/templates /root/.pandoc/templates \
  && mkdir ${HOME}/.pandoc \
  && ln -s /opt/pandoc/templates ${HOME}/.pandoc/templates \
  && chown -R ${CT_USER}:${CT_GID} ${HOME}/.pandoc

## RStudio wants an /etc/R, will populate from $R_HOME/etc
RUN ln -s /opt/microsoft/ropen/${MRO_VERSION_MAJOR}.${MRO_VERSION_MINOR}.${MRO_VERSION_BUGFIX}/lib64/R/etc /etc/R \
  && echo '\n\
    \n# Configure httr to perform out-of-band authentication if HTTR_LOCALHOST \
    \n# is not set since a redirect to localhost may not work depending upon \
    \n# where this Docker container is running. \
    \nif(is.na(Sys.getenv("HTTR_LOCALHOST", unset=NA))) { \
    \n  options(httr_oob_default = TRUE) \
    \n}' >> /etc/R/Rprofile.site \
  && echo "PATH=${PATH}" >> /etc/R/Renviron \
  ## Favor the system version of Pandoc over the broken version shipped with
  ## RStudio
  && echo 'Sys.setenv(RSTUDIO_PANDOC="/usr/bin/pandoc")' >> /etc/R/Rprofile.site

## Prevent rstudio from deciding to use /usr/bin/R if a user apt-get installs a package
RUN echo 'rsession-which-r=/usr/bin/R' >> /etc/rstudio/rserver.conf \
  ## use more robust file locking to avoid errors when using shared volumes:
  && echo 'lock-type=advisory' >> /etc/rstudio/file-locks \
  ## Set up S6 init system
  && wget -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-amd64.tar.gz \
  && tar xzf /tmp/s6-overlay-amd64.tar.gz -C / \
  && rm /tmp/s6-overlay-amd64.tar.gz \
  && mkdir -p /etc/services.d/rstudio \
  && echo '#!/usr/bin/with-contenv bash \
          \n## load /etc/environment vars first: \
          \n for line in $( cat /etc/environment ) ; do export $line ; done \
          \n exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0' \
          > /etc/services.d/rstudio/run \
  && echo '#!/bin/bash \
          \n rstudio-server stop' \
          > /etc/services.d/rstudio/finish \
  && mkdir -p ${HOME}/.rstudio/monitored/user-settings \
  && echo 'alwaysSaveHistory="0" \
          \nloadRData="0" \
          \nsaveAction="0"' \
          > ${HOME}/.rstudio/monitored/user-settings/user-settings \
  && mkdir ${HOME}/kitematic \
  && chown -R ${CT_USER}:${CT_GID} ${HOME}/kitematic \
  && chown -R ${CT_USER}:${CT_GID} ${HOME}/bin \
  && chown -R ${CT_USER}:${CT_GID} ${HOME}/.rstudio \
  && chown -R ${CT_USER}:${CT_GID} ${HOME}/work \
  && rm ${HOME}/.wget-hsts

## running with "-e ADD=shiny" adds shiny server
COPY add_shiny.sh /etc/cont-init.d/add
COPY userconf.sh /etc/cont-init.d/userconf
COPY disable_auth_rserver.conf /etc/rstudio/disable_auth_rserver.conf
COPY pam-helper.sh /usr/lib/rstudio-server/bin/pam-helper
COPY demo.R ${HOME}/work

EXPOSE 8787

## automatically link a shared volume for kitematic users
VOLUME ${HOME}/kitematic

ARG VCS_URL=${VCS_URL}
ARG VCS_REF=${VCS_REF}
ARG BUILD_DATE=${BUILD_DATE}

# Add image metadata
LABEL org.label-schema.license="https://opensource.org/licenses/MIT" \
    org.label-schema.vendor="Dockerfile provided by Mark Coggeshall, influenced by rocker/rstudio" \
  org.label-schema.name="RStudio-Server paired with Microsoft R Open" \
  org.label-schema.description="Docker images of RStudio-Server paired with Microsoft R Open (MRO) with the Intel® Math Kernel Libraries (MKL)." \
  org.label-schema.vcs-url=${VCS_URL} \
  org.label-schema.vcs-ref=${VCS_REF} \
  org.label-schema.build-date=${BUILD_DATE} \
  maintainer="Mark Coggeshall <mark.coggeshall@gmail.com>"

WORKDIR ${HOME}/work

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "/bin/bash", "/usr/local/bin/entrypoint.sh" ]
CMD ["/init"]
