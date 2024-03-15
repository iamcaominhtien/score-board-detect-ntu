FROM python:3.11-bookworm
LABEL authors="TienMinhCao"

# install dependencies
RUN apt-get update && apt-get install -y \
    python3-dev \
    python3-pip \
    python3-venv \
    git \
    && rm -rf /var/lib/apt/lists/*

# set environment variables \
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# set work directory
WORKDIR /app

# install packages in requirements.txt
COPY ./requirements.txt /app/requirements.txt
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# copy project
COPY . /app/