FROM library/redis:6.0.9
COPY service/redis/redis.conf /etc/redis/redis-rc.conf
CMD ["redis-server", "/etc/redis/redis-rc.conf"]
