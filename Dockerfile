# Source of this Dockerfile
# https://gist.github.com/hermanbanken/96f0ff298c162a522ddbba44cad31081

FROM nginx:1.15.12-alpine AS builder

# nginx:1.15.12-alpine contains NGINX_VERSION environment variable, like so:
# ENV NGINX_VERSION 1.15.12

# Our NCHAN version
ENV NCHAN_VERSION 1.2.5

# Download sources
RUN wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O nginx.tar.gz && \
  wget "https://github.com/slact/nchan/archive/v${NCHAN_VERSION}.tar.gz" -O nchan.tar.gz

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

# Reuse same cli arguments as the nginx:1.15.12-alpine image used to build
RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
	tar -zxC /usr/src -f nginx.tar.gz && \
  tar -xzvf "nchan.tar.gz" && \
  NCHANDIR="$(pwd)/nchan-${NCHAN_VERSION}" && \
  cd /usr/src/nginx-$NGINX_VERSION && \
  ./configure --with-compat $CONFARGS --add-dynamic-module=$NCHANDIR && \
  make && make install

FROM nginx:1.15.12-alpine
# Extract the dynamic module NCHAN from the builder image
COPY --from=builder /usr/local/nginx/modules/ngx_nchan_module.so /usr/local/nginx/modules/ngx_nchan_module.so
# RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/nginx.conf
# COPY default.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]