FROM nginx:stable-alpine

ADD app_example/nginx.confg /etc/nginx/nginx.conf

RUN nginx -t
