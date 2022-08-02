FROM nginxinc/nginx-unprivileged:latest
COPY ./requirements.txt /tmp
USER root
# Install python and scripts
ENV PYTHONUNBUFFERED=1
RUN apt-get update 
RUN apt-get -y install python3 python3-pip && ln -sf python3 /usr/bin/python
RUN pip3 install --no-cache --upgrade pip setuptools
RUN pip3 install -r /tmp/requirements.txt
COPY ./scripts/*.py /usr/local/bin/

# Install cron and cronjob
RUN apt-get -y install cron
COPY ./scripts/bke-cron /etc/cron.d/bke-cron
RUN chmod 0644 /etc/cron.d/bke-cron
RUN chmod gu+s /usr/sbin/cron
RUN crontab /etc/cron.d/bke-cron
RUN touch /var/log/cron.log
RUN touch /var/run/crond.pid && chmod 777 /var/run/crond.pid
USER 1001
CMD ["sh", "-c", "cron ; nginx -g daemon off"]
