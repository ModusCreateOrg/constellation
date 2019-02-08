FROM centos:latest AS k8s-webapp

# setup rpm repos, install base packages and create virtual env in a single step
RUN yum install -y https://centos7.iuscommunity.org/ius-release.rpm \
    && yum update  -y \
    && yum install -y \
        python36u python36u-libs python36u-devel \
        python36u-pip uwsgi-plugin-python36u uwsgi \
        gcc make glibc-devel kernel-headers \
        pcre pcre-devel pcre2 pcre2-devel \
        postgresql-devel \
    && yum clean all \
    && mkdir -p /app/socket \
    && chmod 777 /app/socket \
    && python3.6 -m venv --copies --clear /app/venv

# Copy in your requirements file
ADD src/requirements.txt /app/requirements.txt

# Copy in config-app
ADD config-app.sh /app/config-app.sh

# Copy in bin
ADD bin /app/bin

# Copy in bin
ADD src /app/src

# Copy in html
ADD html /app/html

# setup python packages
RUN /app/venv/bin/pip install -U pip \
    && /bin/sh -c "/app/venv/bin/pip install --no-cache-dir -r /app/requirements.txt"

# setup nginx
RUN yum install -y nginx
ADD config/nginx.conf /etc/nginx/nginx.conf
ADD config/app.conf /etc/nginx/conf.d/app.conf

EXPOSE 80

#ENTRYPOINT ["/app/bin/docker-entrypoint.sh"]
CMD ["/app/bin/run.sh"]

