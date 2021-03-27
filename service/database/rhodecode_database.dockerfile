ARG POSTGRES_BUILD
FROM library/postgres:$POSTGRES_BUILD

COPY service/database/customized.conf /etc/conf.d/pg_customized.conf
CMD ["postgres", "-c", "log_statement=ddl"]