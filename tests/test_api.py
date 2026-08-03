"""
Smoke tests for the FastAPI app's route wiring and schemas.

These tests avoid requiring a live Postgres connection by only checking
app configuration and the health endpoint's error-handling path.
Full integration tests (hitting real KPI endpoints) should run in CI
against the ephemeral Postgres service — see .github/workflows/ci.yml.
"""
from fastapi.testclient import TestClient

from api.main import app

client = TestClient(app)


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()


def test_health_endpoint_returns_status_even_if_db_unreachable():
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert "status" in body
    assert "database" in body


def test_openapi_schema_includes_expected_routes():
    schema = client.get("/openapi.json").json()
    paths = schema["paths"]
    assert "/kpi/revenue" in paths
    assert "/kpi/revenue/monthly" in paths
    assert "/customers/rfm" in paths
    assert "/customers/clv" in paths
    assert "/products/performance" in paths
