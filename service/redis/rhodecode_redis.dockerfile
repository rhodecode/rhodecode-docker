ARG REDIS_BUILD
FROM library/redis:$REDIS_BUILD
COPY service/redis/redis.conf /etc/redis/redis-rc.conf
CMD ["redis-server", "/etc/redis/redis-rc.conf"]
