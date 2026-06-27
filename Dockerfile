FROM python:3.8-slim-bullseye

RUN apt update -y && apt install -y awscli curl
WORKDIR /app

# Install tensorflow first using curl with retry logic to avoid download timeouts
RUN pip install --upgrade pip
RUN curl --retry 5 --retry-delay 5 -L -o /tmp/tensorflow-2.9.2-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl https://files.pythonhosted.org/packages/9c/9a/0f6a641141586dad78e48b04df7cc03960298a6738f628b3d9ee0b5009e0/tensorflow-2.9.2-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl && pip install --no-cache-dir /tmp/tensorflow-2.9.2-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl && rm /tmp/tensorflow-2.9.2-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl

COPY . /app
RUN pip install --no-cache-dir -r requirements.txt

CMD ["python3", "app.py"]
