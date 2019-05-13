# Source of this Dockerfile
# https://gist.github.com/hermanbanken/96f0ff298c162a522ddbba44cad31081

FROM nginx:1.15.0-alpine AS builder

# nginx:1.15.0-alpine contains NGINX_VERSION environment variable, like so:
# ENV NGINX_VERSION 1.15.0

# Our NCHAN version
ENV NGINX_RTMP_MODULE_VERSION 1.2.1

# Download sources
RUN wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O nginx.tar.gz && \
  wget "https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_MODULE_VERSION}.tar.gz" -O rtmp_module.tar.gz

# For latest build deps, see https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine/Dockerfile
RUN apk add --no-cache --virtual .build-deps \
  gcc \
  libc-dev \
  make \
  openssl-dev \
  pcre-dev \
  zlib-dev \
  linux-headers \
  curl \
  gnupg \
  libxslt-dev \
  gd-dev \
  geoip-dev

# Reuse same cli arguments as the nginx:1.15.0-alpine image used to build
RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
  tar -zxC /usr/src -f nginx.tar.gz && \
  tar -xzvf "rtmp_module.tar.gz" && \
  RTMPDIR="/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}" && \
  cd /usr/src/nginx-$NGINX_VERSION && \
  ./configure --with-compat $CONFARGS --add-dynamic-module=$RTMPDIR && \
  make && make install

FROM nginx:1.15.0-alpine

RUN apk add --no-cache ffmpeg

RUN mkdir -p /etc/nginx/logs/
RUN touch /etc/nginx/logs/access.log
RUN touch /etc/nginx/logs/error.log

RUN mkdir -p /var/www/hls/live
RUN mkdir -p /var/www/videos

# Extract the dynamic module NCHAN from the builder image
COPY --from=builder /usr/local/nginx/modules/ngx_rtmp_module.so /usr/local/nginx/modules/ngx_rtmp_module.so
# RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/nginx.conf
# COPY default.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
EXPOSE 1935
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]