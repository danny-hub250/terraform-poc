FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir flask psycopg2-binary gunicorn requests
COPY app.py .
EXPOSE 8080
CMD ["gunicorn", "-b", "0.0.0.0:8080", "app:app"]
