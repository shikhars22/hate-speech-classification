FROM python:3.8-slim-bullseye

RUN apt update -y && apt install awscli -y
WORKDIR /app

COPY . /app
RUN pip install --upgrade pip && pip install --default-timeout=1000 --no-cache-dir -r requirements.txt

CMD ["python3", "app.py"]
