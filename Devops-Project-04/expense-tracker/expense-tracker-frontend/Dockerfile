FROM nginx:latest
RUN rm -rf /usr/share/nginx/html/*
COPY default /etc/nginx/conf.d/default.conf
COPY dist/ /usr/share/nginx/html/
CMD ["nginx", "-g", "daemon off;"]
