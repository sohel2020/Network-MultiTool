FROM alpine:3.12

MAINTAINER sohel2020@gmail.com

EXPOSE 80 443

# Install some tools in the container and generate self-signed SSL certificates.
# Packages are listed in alphabetical order, for ease of readability and ease of maintenance.
RUN  apk update \
    &&  apk add aws-cli apache2-utils bash bind-tools busybox-extras curl ethtool git \
                iperf3 iproute2 iputils jq lftp mtr mysql-client \
                netcat-openbsd net-tools nginx nmap openssh-client openssl \
                perl-net-telnet postgresql-client procps rsync socat tcpdump tshark wget \
    &&  mkdir /certs \
    &&  chmod 700 /certs \
    &&  openssl req \
        -x509 -newkey rsa:2048 -nodes -days 3650 \
        -keyout /certs/server.key -out /certs/server.crt -subj '/CN=localhost'

ENV KUBE_VERSION=1.20.2
ENV HELM_VERSION=3.5.2

RUN apk add --no-cache ca-certificates bash git openssh curl \
    && wget -q https://storage.googleapis.com/kubernetes-release/release/v${KUBE_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && wget -q https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && chmod g+rwx /root \
    && mkdir /config \
    && chmod g+rwx /config \
    && helm repo add "stable" "https://charts.helm.sh/stable" --force-update


# Copy a simple index.html to eliminate text (index.html) noise which comes with default nginx image.
# (I created an issue for this purpose here: https://github.com/nginxinc/docker-nginx/issues/234)
COPY index.html /usr/share/nginx/html/

# Copy a custom nginx.conf with log files redirected to stderr and stdout
COPY nginx.conf /etc/nginx/nginx.conf

COPY docker-entrypoint.sh /


# Run the startup script as ENTRYPOINT, which does few things and then starts nginx.
ENTRYPOINT ["/docker-entrypoint.sh"]


# Start nginx in foreground:
CMD ["nginx", "-g", "daemon off;"]
