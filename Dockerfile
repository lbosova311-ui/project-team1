FROM php:8.3-apache-bookworm

LABEL org.opencontainers.image.title="project-team1-myapp" \
      org.opencontainers.image.description="PHP Apache application for project-team1 CI/CD" \
      org.opencontainers.image.vendor="project-team1"

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && printf 'expose_php = Off\n' > "$PHP_INI_DIR/conf.d/security.ini" \
    && printf 'ServerName localhost\nServerTokens Prod\nServerSignature Off\n' > /etc/apache2/conf-available/security-hardening.conf \
    && a2enconf security-hardening

WORKDIR /var/www/html

COPY --chown=www-data:www-data index.php /var/www/html/index.php
RUN chmod 0444 /var/www/html/index.php

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD php -r 'exit(@file_get_contents("http://127.0.0.1/") === false ? 1 : 0);'

CMD ["apache2-foreground"]
