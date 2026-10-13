FROM nginx:alpine

# Tạo thư mục actuator và tệp health trả về HTTP 200 OK
RUN mkdir -p /usr/share/nginx/html/actuator && \
    echo '{"status":"UP","details":{"diskSpace":{"status":"UP"},"ping":{"status":"UP"}}}' > /usr/share/nginx/html/actuator/health && \
    echo '{"application":"Spring Boot Demo App","environment":"production","status":"RUNNING"}' > /usr/share/nginx/html/index.html

# Đổi cổng mặc định Nginx từ 80 sang 8080
RUN sed -i 's/listen       80;/listen       8080;/g' /etc/nginx/conf.d/default.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
