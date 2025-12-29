# SmartWaste

**SmartWaste** is a Smart Garbage Management System that helps cities manage waste collection efficiently:
- Citizens can report garbage with photos and location
- Admins can view all reports, assign tasks to collectors, and track statistics
- Collectors can view assigned tasks, navigate to locations, and mark tasks as completed

🚀 **Project Status:** In Development  
🎯 **Goals:** Provide an efficient tool for waste management and city cleanliness

---

## 🌟 Features

### **For Citizens**
- Report garbage with photo and location
- Track status of submitted reports
- View history of all reports

### **For Admins**
- View all garbage reports with filters
- Assign reports to garbage collectors
- Track statistics and metrics
- Manage collectors and users

### **For Collectors**
- View assigned tasks with location on map
- Navigate to garbage location
- Mark tasks as completed
- View collection history

---

## 🔧 Tech Stack

### **Frontend (Mobile):** 
- Flutter
- Riverpod (State Management)
- Google Maps Flutter
- Firebase Auth
- Image Picker
- Geolocator

### **Backend (REST API):** 
- FastAPI
- SQLAlchemy (ORM)
- PostgreSQL / SQLite
- JWT Authentication
- Role-based Access Control
- File Upload Support

### **Architecture:**
- Clean Architecture
- REST APIs
- JWT Token Authentication
- Role-based Authorization (Citizen, Admin, Collector)

---

## 📂 Project Structure

```
SmartWaste/
├── mobile/            # Flutter mobile app
├── backend/           # FastAPI backend
└── README.md          # This file
```

---

## 🛠 Installation

### Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env and set JWT_SECRET_KEY

# Run server
uvicorn app.main:app --reload
```

Backend will run on http://localhost:8000

### Mobile Setup

```bash
cd mobile

# Install dependencies
flutter pub get

# Run app
flutter run
```

---

## 🔐 API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login user

### Citizen Endpoints
- `POST /api/v1/reports` - Create garbage report
- `GET /api/v1/reports` - Get my reports
- `GET /api/v1/reports/{id}` - Get report details

### Admin Endpoints
- `GET /api/v1/admin/reports` - Get all reports
- `PUT /api/v1/admin/reports/{id}/assign` - Assign to collector
- `GET /api/v1/admin/collectors` - Get all collectors
- `GET /api/v1/admin/stats` - Get statistics

### Collector Endpoints
- `GET /api/v1/collector/tasks` - Get assigned tasks
- `GET /api/v1/collector/tasks/{id}` - Get task details
- `PUT /api/v1/collector/tasks/{id}/complete` - Mark as completed
- `GET /api/v1/collector/history` - Get completed tasks

---

## 📱 Screenshots

*(Screenshots will be added after UI implementation)*

---

## 📜 License

[MIT License](LICENSE)
