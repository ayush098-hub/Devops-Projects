FROM python:3.12-slim
WORKDIR /usr/src/app
COPY codes /usr/src/app/codes
RUN pip3 install -r /usr/src/app/codes/requirements.txt
WORKDIR /usr/src/app/codes
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
