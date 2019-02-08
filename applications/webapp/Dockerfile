FROM centos:latest AS k8s-webapp

# setup rpm repos, install base packages and create virtual env in a single step
RUN	yum install -y https://centos7.iuscommunity.org/ius-release.rpm \
	&& yum update  -y \
	&& yum install -y \
		python36u python36u-libs python36u-devel \
		python36u-pip uwsgi-plugin-python36u uwsgi \
		gcc make glibc-devel kernel-headers \
		pcre pcre-devel pcre2 pcre2-devel \
		postgresql-devel \
	&& yum clean all

# Copy in config-app
ADD config-app.sh /app/config-app.sh

# Copy in bin
ADD bin /app/bin

# setup nginx
RUN yum install -y nginx

ADD html/ /usr/share/nginx/html

EXPOSE 80

#ENTRYPOINT ["/app/bin/docker-entrypoint.sh"]
CMD ["/app/bin/run.sh"]

