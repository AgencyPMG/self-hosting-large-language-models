FROM nginx:stable-alpine

ADD app_example/nginx.conf /etc/nginx/nginx.conf

RUN nginx -t
