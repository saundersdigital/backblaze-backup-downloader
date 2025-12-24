FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY b2_downloader.py .

CMD ["python", "b2_downloader.py"]