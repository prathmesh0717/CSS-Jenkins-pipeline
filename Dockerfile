FROM nginx
COPY . /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "deamon-off;"]
