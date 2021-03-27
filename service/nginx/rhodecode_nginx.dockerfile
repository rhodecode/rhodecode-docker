ARG NGINX_BUILD
FROM library/nginx:$NGINX_BUILD

ENV NGINX_ENTRYPOINT_QUIET_LOGS=1

RUN mkdir -p /etc/nginx/sites-enabled/
RUN mkdir -p /var/log/rhodecode/nginx
COPY service/nginx/nginx.conf /etc/nginx/nginx.conf
COPY service/nginx/http.conf /etc/nginx/sites-enabled/http.conf
COPY service/nginx/proxy.conf /etc/nginx/proxy.conf

VOLUME /var/log/rhodecode

#TODO enable amplify