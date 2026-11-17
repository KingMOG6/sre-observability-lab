import os
import random
import time

from flask import Flask, g, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

app = Flask(__name__)

SERVICE = "payments"
ERROR_RATE = float(os.getenv("ERROR_RATE", "0"))   # 0.0 to 1.0
LATENCY_MS = int(os.getenv("LATENCY_MS", "20"))

REQUESTS = Counter(
    "http_requests_total", "Total HTTP requests",
    ["service", "method", "path", "status"],
)
LATENCY = Histogram(
    "http_request_duration_seconds", "Request latency in seconds",
    ["service", "path"],
    buckets=(0.05, 0.1, 0.25, 0.5, 1, 2.5),
)


@app.before_request
def start_timer():
    g.start = time.perf_counter()


@app.after_request
def record_metrics(response):
    if request.path != "/metrics":
        LATENCY.labels(SERVICE, request.path).observe(time.perf_counter() - g.start)
        REQUESTS.labels(SERVICE, request.method, request.path, response.status_code).inc()
    return response


@app.route("/pay")
def pay():
    time.sleep(LATENCY_MS / 1000 * random.uniform(0.5, 1.5))
    if random.random() < ERROR_RATE:
        return jsonify(error="payment gateway unavailable"), 500
    return jsonify(status="paid")


@app.route("/health")
def health():
    return jsonify(status="ok")


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
