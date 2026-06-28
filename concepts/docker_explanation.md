# Dockerfile Explanation - Hate Speech Classification App

This document provides a line-by-line explanation of the project's [Dockerfile](file:///c:/Users/shikh/Downloads/code/gitHub/MLOpsLearning/nlp-project/Dockerfile), explaining the purpose of each instruction and the engineering choices made to ensure a stable, fast, and secure build.

---

## 1. The Dockerfile Source

```dockerfile
FROM python:3.8-slim-bullseye

RUN apt update -y && apt install -y awscli curl
WORKDIR /app

# Install tensorflow first using curl with retry logic to avoid download timeouts
RUN pip install --upgrade pip
RUN curl --retry 5 --retry-delay 5 -L -o /tmp/tensorflow-2.9.2-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl https://files.pythonhosted.org/packages/9c/9a/0f6a641141586dad78e48b04df7cc03960298a6738f628b3d9ee0b5009e0/tensorflow-2.9.2-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl && pip install --no-cache-dir /tmp/tensorflow-2.9.2-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl && rm /tmp/tensorflow-2.9.2-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl

COPY . /app
RUN pip install --no-cache-dir -r requirements.txt

CMD ["python3", "app.py"]
```

---

## 2. Line-by-Line Breakdown

### Line 1: `FROM python:3.8-slim-bullseye`
* **Purpose:** Sets the base operating system and runtime environment.
* **Why `python:3.8-slim-bullseye`:**
  * **Python 3.8:** Recommended for stability with TensorFlow 2.9.2.
  * **slim:** A minimal base Debian image. It excludes developer-oriented packages (such as build tools) to reduce the final image size (approx. 150MB instead of 900MB).
  * **bullseye:** Debian 11. The previous base image used Debian 10 (`buster`), which reached End-Of-Life (EOL), causing `apt` package manager commands to crash with 404 errors during builds. Bullseye has active security updates and repository support.

---

### Line 3: `RUN apt update -y && apt install -y awscli curl`
* **Purpose:** Installs core Linux system tools inside the container.
* **Why these packages:**
  * `awscli`: Essential for syncing model checkpoints and datasets with AWS S3 (`aws s3 cp`).
  * `curl`: Used in the next steps to download large package files stably.
  * `-y`: Automatically accepts confirmation prompts so the build executes non-interactively.
  * `apt update` and `apt install` are chained using `&&` in a single `RUN` instruction to prevent layer cache mismatches.

---

### Line 4: `WORKDIR /app`
* **Purpose:** Creates and switches the active working directory inside the container to `/app`. All subsequent relative paths (`COPY`, `RUN`, `CMD`) will run relative to this folder.

---

### Line 7: `RUN pip install --upgrade pip`
* **Purpose:** Upgrades Python's package installer (`pip`) to the latest version inside the container. Newer versions of `pip` contain better dependency resolution algorithms and build tools.

---

### Line 8: `RUN curl --retry 5 --retry-delay 5 -L -o /tmp/tensorflow-... && pip install ... && rm ...`
* **Purpose:** Stably downloads and installs the heavy **TensorFlow 2.9.2 (512MB)** library using a single line command.
* **Why it is structured this way:**
  1. **Network Resilience (`curl --retry 5 --retry-delay 5`):** Standard `pip install` download sessions over Python's internal socket library are highly fragile. Heavy wheels (like TensorFlow) often get dropped or truncated on hosted runners, resulting in `Hash Mismatch` errors. `curl` will automatically pause and retry the download up to 5 times if a connection drops.
  2. **Absolute Path (`-o /tmp/...`):** Using the absolute `/tmp/` directory avoids any path resolution conflicts before the application code is copied.
  3. **PEP 427 Tag Validation:** The downloaded wheel retains its exact tag filename (`tensorflow-2.9.2-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl`). `pip` requires this tag structure to validate CPU/platform compatibility during installation.
  4. **Layer Optimization (`&& rm ...`):** Chaining the installation and deletion of the wheel in the same command layer prevents the 512MB installer wheel from bloating the final Docker image.

---

### Line 10: `COPY . /app`
* **Purpose:** Copies all code files, scripts, and model configurations from your local repository root on the host machine into the container's `/app` directory.
* **Note:** Files specified in `.dockerignore` (such as `.git`, local Python environments, and `graphify-out/`) are automatically excluded to keep the image lightweight.

---

### Line 11: `RUN pip install --no-cache-dir -r requirements.txt`
* **Purpose:** Installs the remaining dependencies listed in `requirements.txt` (such as `pandas`, `numpy`, `fastapi`, and `uvicorn`).
* **Optimization:**
  * Since TensorFlow is already pre-installed, `pip` detects it and skips downloading it again.
  * `--no-cache-dir` prevents `pip` from saving installer wheels locally inside the layer, keeping the final Docker container size as small as possible.

---

### Line 13: `CMD ["python3", "app.py"]`
* **Purpose:** Specifies the default command that runs automatically when the Docker container starts up. This launches the FastAPI server (`app.py`), listening on port `8080` for API training or prediction traffic.
