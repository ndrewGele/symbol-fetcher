FROM rocker/r-ver:4.2.2

RUN apt-get update
RUN apt-get install -y libcurl4-openssl-dev
RUN apt-get install -y libpq-dev
RUN apt-get install -y libssl-dev
RUN apt-get install -y odbc-postgresql
RUN apt-get install -y unixodbc-dev
RUN apt-get install -y libxml2-dev
# RUN apt-get install -y zlib1g-dev

WORKDIR /code

COPY ./ /code

RUN R -e "renv::restore()"

CMD ["Rscript", "main.R"]