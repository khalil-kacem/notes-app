FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY index.html style.css app.js /usr/share/nginx/html/
RUN addgroup -g 1001 -S nginx-group && \
    adduser -S nginx-user -u 1001 && \
    chown -R nginx-user:nginx-group /usr/share/nginx/html
USER nginx-user
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1
