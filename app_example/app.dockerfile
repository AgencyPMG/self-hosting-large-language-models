FROM python:3.12-slim-bookworm

EXPOSE 8000

ADD requirements.txt app_example/main.py /app/

WORKDIR /app

RUN apt-get update \
    && apt-get -y install gcc python3-dev \
    && pip install -r requirements.txt

CMD ["uvicorn",  "main:app", "--host", "0.0.0.0", "--port", "8000"]
