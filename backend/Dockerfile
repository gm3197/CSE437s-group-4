FROM docker.io/python:3
WORKDIR /app
RUN pip install -r /app/requirements.txt
RUN apt update -y
RUN apt install tesseract-ocr -y
COPY ./src /app
