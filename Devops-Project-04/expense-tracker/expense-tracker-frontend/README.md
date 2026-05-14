# Expense Tracker Frontend

React + Vite frontend for the Expense Tracker backend.

## Backend Requirements

- Spring Boot backend running on `http://localhost:8080`
- PostgreSQL may run on port `5433`; this is configured in the backend, not in the frontend.

## Run

```bash
npm install
npm run dev
```

Open:
- http://localhost:3000

## Default API URL

Configured in `index.html`:

```html
window.API_URL = "http://localhost:8080/api";
```
