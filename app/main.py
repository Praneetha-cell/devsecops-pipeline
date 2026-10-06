"""Small Flask service used as the payload for the DevSecOps pipeline."""
import os
import time

from flask import Flask, Response, jsonify, request
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Histogram,
    generate_latest,
)

app = Flask(__name__)

REQUEST_COUNT = Counter(
    "app_requests_total", "Total HTTP requests", ["method", "endpoint", "status"]
)
REQUEST_LATENCY = Histogram(
    "app_request_latency_seconds", "Request latency in seconds", ["endpoint"]
)


@app.before_request
def _start_timer():
    request._start_time = time.perf_counter()


@app.after_request
def _record_metrics(response):
    start = getattr(request, "_start_time", None)
    if start is not None and request.endpoint:
        REQUEST_LATENCY.labels(request.endpoint).observe(time.perf_counter() - start)
        REQUEST_COUNT.labels(request.method, request.endpoint, response.status_code).inc()
    return response


def add(a: float, b: float) -> float:
    return a + b


@app.route("/")
def index():
    return jsonify(message="DevSecOps pipeline demo", version=os.getenv("APP_VERSION", "dev"))


@app.route("/healthz")
def healthz():
    return jsonify(status="ok")


@app.route("/add")
def add_route():
    try:
        a = float(request.args.get("a", ""))
        b = float(request.args.get("b", ""))
    except ValueError:
        return jsonify(error="a and b must be numbers"), 400
    return jsonify(result=add(a, b))


@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    # Bind to all interfaces only inside the container; override with HOST for local runs.
    app.run(host=os.getenv("HOST", "0.0.0.0"), port=int(os.getenv("PORT", "8080")))  # nosec B104
