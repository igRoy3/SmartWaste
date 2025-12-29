"""Tests for garbage management endpoints."""
import io
import pytest
from fastapi.testclient import TestClient


def test_register_user(client: TestClient):
    """Test user registration."""
    response = client.post(
        "/api/v1/auth/register",
        json={
            "uid": "test_user_123",
            "email": "test@example.com",
            "name": "Test User",
            "role": "citizen"
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["user"]["role"] == "citizen"


def test_login_user(client: TestClient):
    """Test user login."""
    # First register
    client.post(
        "/api/v1/auth/register",
        json={
            "uid": "test_login_123",
            "email": "login@example.com",
            "name": "Login User",
            "role": "citizen"
        }
    )
    
    # Then login
    response = client.post(
        "/api/v1/auth/login",
        json={"uid": "test_login_123"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data


def test_create_garbage_report(client: TestClient):
    """Test creating a garbage report."""
    # Register and get token
    reg_response = client.post(
        "/api/v1/auth/register",
        json={
            "uid": "test_reporter_123",
            "email": "reporter@example.com",
            "name": "Reporter User",
            "role": "citizen"
        }
    )
    token = reg_response.json()["access_token"]
    
    # Create a fake image file
    fake_image = io.BytesIO(b"fake image content")
    
    # Create report
    response = client.post(
        "/api/v1/reports",
        headers={"Authorization": f"Bearer {token}"},
        data={
            "location_lat": 40.7128,
            "location_lng": -74.0060,
            "address": "123 Test St",
            "description": "Large pile of garbage"
        },
        files={"photo": ("test.jpg", fake_image, "image/jpeg")}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "pending"
    assert data["location_lat"] == 40.7128


def test_get_my_reports(client: TestClient):
    """Test getting user's own reports."""
    # Register and get token
    reg_response = client.post(
        "/api/v1/auth/register",
        json={
            "uid": "test_viewer_123",
            "email": "viewer@example.com",
            "name": "Viewer User",
            "role": "citizen"
        }
    )
    token = reg_response.json()["access_token"]
    
    # Create a report
    fake_image = io.BytesIO(b"fake image content")
    client.post(
        "/api/v1/reports",
        headers={"Authorization": f"Bearer {token}"},
        data={
            "location_lat": 40.7128,
            "location_lng": -74.0060,
            "description": "Test report"
        },
        files={"photo": ("test.jpg", fake_image, "image/jpeg")}
    )
    
    # Get reports
    response = client.get(
        "/api/v1/reports",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 1


def test_admin_get_all_reports(client: TestClient):
    """Test admin viewing all reports."""
    # Register admin
    admin_response = client.post(
        "/api/v1/auth/register",
        json={
            "uid": "test_admin_123",
            "email": "admin@example.com",
            "name": "Admin User",
            "role": "admin"
        }
    )
    admin_token = admin_response.json()["access_token"]
    
    # Get all reports
    response = client.get(
        "/api/v1/admin/reports",
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    assert response.status_code == 200


def test_admin_assign_report(client: TestClient):
    """Test admin assigning report to collector."""
    # Register admin
    admin_response = client.post(
        "/api/v1/auth/register",
        json={
            "uid": "test_admin_assign_123",
            "email": "admin_assign@example.com",
            "name": "Admin Assign User",
            "role": "admin"
        }
    )
    admin_token = admin_response.json()["access_token"]
    
    # Register collector
    collector_response = client.post(
        "/api/v1/auth/register",
        json={
            "uid": "test_collector_123",
            "email": "collector@example.com",
            "name": "Collector User",
            "role": "collector"
        }
    )
    collector_id = collector_response.json()["user"]["id"]
    
    # Register citizen and create report
    citizen_response = client.post(
        "/api/v1/auth/register",
        json={
            "uid": "test_citizen_report_123",
            "email": "citizen_report@example.com",
            "name": "Citizen Report User",
            "role": "citizen"
        }
    )
    citizen_token = citizen_response.json()["access_token"]
    
    fake_image = io.BytesIO(b"fake image content")
    report_response = client.post(
        "/api/v1/reports",
        headers={"Authorization": f"Bearer {citizen_token}"},
        data={
            "location_lat": 40.7128,
            "location_lng": -74.0060,
            "description": "Test assignment"
        },
        files={"photo": ("test.jpg", fake_image, "image/jpeg")}
    )
    report_id = report_response.json()["id"]
    
    # Assign report
    response = client.put(
        f"/api/v1/admin/reports/{report_id}/assign",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"collector_id": collector_id}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "assigned"
    assert data["collector_id"] == collector_id


def test_collector_get_tasks(client: TestClient):
    """Test collector viewing assigned tasks."""
    # Register collector
    collector_response = client.post(
        "/api/v1/auth/register",
        json={
            "uid": "test_collector_tasks_123",
            "email": "collector_tasks@example.com",
            "name": "Collector Tasks User",
            "role": "collector"
        }
    )
    collector_token = collector_response.json()["access_token"]
    
    # Get tasks
    response = client.get(
        "/api/v1/collector/tasks",
        headers={"Authorization": f"Bearer {collector_token}"}
    )
    assert response.status_code == 200


def test_collector_complete_task(client: TestClient):
    """Test collector completing a task."""
    # Setup: admin, collector, citizen, and report
    admin_response = client.post(
        "/api/v1/auth/register",
        json={
            "uid": "test_admin_complete_123",
            "email": "admin_complete@example.com",
            "name": "Admin Complete User",
            "role": "admin"
        }
    )
    admin_token = admin_response.json()["access_token"]
    
    collector_response = client.post(
        "/api/v1/auth/register",
        json={
            "uid": "test_collector_complete_123",
            "email": "collector_complete@example.com",
            "name": "Collector Complete User",
            "role": "collector"
        }
    )
    collector_token = collector_response.json()["access_token"]
    collector_id = collector_response.json()["user"]["id"]
    
    citizen_response = client.post(
        "/api/v1/auth/register",
        json={
            "uid": "test_citizen_complete_123",
            "email": "citizen_complete@example.com",
            "name": "Citizen Complete User",
            "role": "citizen"
        }
    )
    citizen_token = citizen_response.json()["access_token"]
    
    # Create report
    fake_image = io.BytesIO(b"fake image content")
    report_response = client.post(
        "/api/v1/reports",
        headers={"Authorization": f"Bearer {citizen_token}"},
        data={
            "location_lat": 40.7128,
            "location_lng": -74.0060,
            "description": "Test completion"
        },
        files={"photo": ("test.jpg", fake_image, "image/jpeg")}
    )
    report_id = report_response.json()["id"]
    
    # Admin assigns report
    client.put(
        f"/api/v1/admin/reports/{report_id}/assign",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"collector_id": collector_id}
    )
    
    # Collector completes task
    response = client.put(
        f"/api/v1/collector/tasks/{report_id}/complete",
        headers={"Authorization": f"Bearer {collector_token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "completed"
    assert data["completed_at"] is not None


def test_admin_get_stats(client: TestClient):
    """Test admin getting statistics."""
    # Register admin
    admin_response = client.post(
        "/api/v1/auth/register",
        json={
            "uid": "test_admin_stats_123",
            "email": "admin_stats@example.com",
            "name": "Admin Stats User",
            "role": "admin"
        }
    )
    admin_token = admin_response.json()["access_token"]
    
    # Get stats
    response = client.get(
        "/api/v1/admin/stats",
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "total_reports" in data
    assert "pending_reports" in data
    assert "completed_reports" in data
