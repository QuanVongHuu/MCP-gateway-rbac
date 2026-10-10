FROM python:3.13-slim
RUN pip install --no-cache-dir "mcp==1.30.0"
WORKDIR /app
COPY mockkit.py ./
COPY radar/ radar/
COPY spark-history/ spark-history/
COPY openmetadata/ openmetadata/
COPY dbt/ dbt/
COPY airflow/ airflow/
ENV PYTHONPATH=/app PYTHONUNBUFFERED=1 PORT=8000
EXPOSE 8000
USER 65534
# One image for all mocks; the Deployment picks one with args: ["<mock>/server.py"]
ENTRYPOINT ["python"]
CMD ["radar/server.py"]
