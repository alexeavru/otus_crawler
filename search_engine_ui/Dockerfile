FROM python:3.6.0-alpine

WORKDIR /app
ADD . /app

RUN pip install -r /app/requirements.txt -r /app/requirements-test.txt

ENV MONGO mongo_db
ENV MONGO_PORT mongo_port
ENV FLASK_APP ui.py

EXPOSE 8000

ENTRYPOINT cd ui && gunicorn ui:app -b 0.0.0.0
