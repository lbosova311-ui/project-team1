FROM wordpress:6-php8.3-apache

LABEL org.opencontainers.image.title="project-team1-wordpress" \
      org.opencontainers.image.description="Hardened WordPress Apache image for project-team1" \
      org.opencontainers.image.vendor="project-team1"

# PHP production tuning and security hardening
RUN { \
      echo 'expose_php = Off'; \
      echo 'upload_max_filesize = 64M'; \
      echo 'post_max_size = 64M'; \
      echo 'memory_limit = 256M'; \
      echo 'max_execution_time = 120'; \
      echo 'max_input_vars = 3000'; \
    } > /usr/local/etc/php/conf.d/custom.ini \
    && printf 'ServerName localhost\nServerTokens Prod\nServerSignature Off\n' > /etc/apache2/conf-available/security-hardening.conf \
    && a2enconf security-hardening

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD php -r 'exit(@file_get_contents("http://127.0.0.1/wp-login.php") === false ? 1 : 0);'
