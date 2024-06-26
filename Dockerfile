FROM rocker/r-ver:4.3.0

RUN apt-get update
RUN apt-get install -y libcurl4-openssl-dev
RUN apt-get install -y libpq-dev
RUN apt-get install -y libssl-dev
RUN apt-get install -y odbc-postgresql
RUN apt-get install -y unixodbc-dev
RUN apt-get install -y libxml2-dev

WORKDIR /code

COPY ./ /code

RUN R -e "renv::restore()"

CMD ["Rscript", "main.R"]

LABEL org.opencontainers.image.source https://github.com/ndrewgele/symbol-fetcher
LABEL org.opencontainers.image.description "A service for finding stock symbols to use in the Argosy application."
