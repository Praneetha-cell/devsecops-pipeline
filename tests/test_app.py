import pytest

from app.main import add, app


@pytest.fixture()
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_add_function():
    assert add(2, 3) == 5


def test_index(client):
    r = client.get("/")
    assert r.status_code == 200
    assert "message" in r.get_json()


def test_healthz(client):
    r = client.get("/healthz")
    assert r.status_code == 200
    assert r.get_json() == {"status": "ok"}


def test_add_route(client):
    r = client.get("/add?a=1.5&b=2")
    assert r.status_code == 200
    assert r.get_json()["result"] == 3.5


def test_add_route_rejects_bad_input(client):
    r = client.get("/add?a=x&b=2")
    assert r.status_code == 400


def test_metrics_exposed(client):
    client.get("/healthz")
    r = client.get("/metrics")
    assert r.status_code == 200
    assert b"app_requests_total" in r.data
