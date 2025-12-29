# SmartWaste API Documentation

## Overview

The SmartWaste API is a RESTful service built with FastAPI that provides endpoints for managing garbage collection reports. It supports three user roles: citizens, administrators, and collectors.

## Base URL

```
Development: http://localhost:8000/api/v1
```

## Authentication

The API uses JWT (JSON Web Token) for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your_token>
```

### Getting a Token

Register or login to receive a JWT token that expires in 7 days.

## User Roles

- **Citizen**: Can create and view their own garbage reports
- **Admin**: Can view all reports, assign them to collectors, and access statistics
- **Collector**: Can view assigned tasks, update their status, and mark them as completed

## Endpoints

### Authentication Endpoints

#### Register User
```http
POST /auth/register
Content-Type: application/json

{
  "uid": "unique_user_id",
  "email": "user@example.com",
  "name": "John Doe",
  "role": "citizen"  // Options: citizen, admin, collector
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "uid": "unique_user_id",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "citizen"
  }
}
```

#### Login User
```http
POST /auth/login
Content-Type: application/json

{
  "uid": "unique_user_id"
}
```

### Citizen Endpoints

#### Create Garbage Report
```http
POST /reports
Authorization: Bearer <token>
Content-Type: multipart/form-data

location_lat: 40.7128
location_lng: -74.0060
address: "123 Main St, New York, NY"
description: "Large pile of garbage on the sidewalk"
photo: <image_file>
```

**Response:**
```json
{
  "id": 1,
  "citizen_id": 1,
  "collector_id": null,
  "photo_url": "/uploads/garbage_photos/abc123.jpg",
  "location_lat": 40.7128,
  "location_lng": -74.0060,
  "address": "123 Main St, New York, NY",
  "description": "Large pile of garbage on the sidewalk",
  "status": "pending",
  "created_at": "2025-12-29T10:00:00Z",
  "updated_at": "2025-12-29T10:00:00Z",
  "assigned_at": null,
  "completed_at": null
}
```

#### Get My Reports
```http
GET /reports?skip=0&limit=100
Authorization: Bearer <token>
```

#### Get Report Details
```http
GET /reports/{report_id}
Authorization: Bearer <token>
```

### Admin Endpoints

#### Get All Reports
```http
GET /admin/reports?status_filter=pending&skip=0&limit=100
Authorization: Bearer <admin_token>
```

**Query Parameters:**
- `status_filter` (optional): Filter by status (pending, assigned, in_progress, completed, rejected)
- `skip`: Number of records to skip (default: 0)
- `limit`: Maximum number of records to return (default: 100, max: 100)

#### Assign Report to Collector
```http
PUT /admin/reports/{report_id}/assign
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "collector_id": 3
}
```

#### Get All Collectors
```http
GET /admin/collectors
Authorization: Bearer <admin_token>
```

**Response:**
```json
[
  {
    "id": 3,
    "name": "Collector One",
    "email": "collector1@example.com",
    "role": "collector"
  },
  {
    "id": 4,
    "name": "Collector Two",
    "email": "collector2@example.com",
    "role": "collector"
  }
]
```

#### Get Statistics
```http
GET /admin/stats
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "total_reports": 150,
  "pending_reports": 25,
  "assigned_reports": 30,
  "in_progress_reports": 15,
  "completed_reports": 75,
  "total_collectors": 10,
  "total_citizens": 200
}
```

### Collector Endpoints

#### Get Assigned Tasks
```http
GET /collector/tasks?skip=0&limit=100
Authorization: Bearer <collector_token>
```

Returns only tasks assigned to the authenticated collector with status "assigned" or "in_progress".

#### Get Task Details
```http
GET /collector/tasks/{task_id}
Authorization: Bearer <collector_token>
```

#### Start Task
```http
PUT /collector/tasks/{task_id}/start
Authorization: Bearer <collector_token>
```

Changes task status from "assigned" to "in_progress".

#### Complete Task
```http
PUT /collector/tasks/{task_id}/complete
Authorization: Bearer <collector_token>
```

Changes task status to "completed" and sets the completion timestamp.

#### Get Completed Tasks
```http
GET /collector/history?skip=0&limit=100
Authorization: Bearer <collector_token>
```

Returns tasks completed by the authenticated collector.

## Report Status Flow

1. **pending**: Initial status when citizen creates a report
2. **assigned**: Admin has assigned the report to a collector
3. **in_progress**: Collector has started working on the task
4. **completed**: Collector has finished the task
5. **rejected**: Admin has rejected the report

## Error Responses

### 400 Bad Request
```json
{
  "detail": "Invalid status"
}
```

### 401 Unauthorized
```json
{
  "detail": "Token has expired"
}
```

### 403 Forbidden
```json
{
  "detail": "Not authorized. Admin role required."
}
```

### 404 Not Found
```json
{
  "detail": "Report not found"
}
```

### 500 Internal Server Error
```json
{
  "detail": "An internal error occurred. Please try again later."
}
```

## Rate Limiting

The API implements rate limiting of 100 requests per minute per IP address. Exceeding this limit will result in a 429 Too Many Requests response.

## Interactive API Documentation

When running the server in development mode, you can access:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

These provide interactive documentation where you can test endpoints directly from your browser.
