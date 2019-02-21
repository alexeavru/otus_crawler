FROM python:3.6.0-alpine

WORKDIR /app
RUN mkdir /app/crawler
ADD ./crawler /app/crawler
COPY requirements.txt /app/requirements.txt
COPY requirements-test.txt /app/requirements-test.txt

RUN pip install -r /app/requirements.txt -r /app/requirements-test.txt

ENV MONGO mongo_db
ENV MONGO_PORT mongo_port
ENV RMQ_HOST rmq_host
ENV RMQ_QUEUE rmq_queue
ENV RMQ_USERNAME rmq_user
ENV RMQ_PASSWORD rmq_pass
ENV CHECK_INTERVAL 1
ENV EXCLUDE_URLS ".*github.com"
ENV URL url

ENTRYPOINT python3 -u crawler/crawler.py $URL
