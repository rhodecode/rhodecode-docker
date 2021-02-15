FROM library/postgres:13.1

COPY service/database/customized.conf /etc/conf.d/pg_customized.conf
CMD ["postgres", "-c", "log_statement=ddl"]