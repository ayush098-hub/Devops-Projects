#!/usr/bin/env bash
set -euo pipefail

APP_NAME="expense-tracker-frontend"
BASE_DIR="${1:-$APP_NAME}"

if [ -e "$BASE_DIR" ]; then
  echo "Target path '$BASE_DIR' already exists. Remove it or pass a new directory name."
  exit 1
fi

mkdir -p "$BASE_DIR/src/components"
cd "$BASE_DIR"

cat > package.json <<'EOF'
{
  "name": "expense-tracker-frontend",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite --host 0.0.0.0 --port 3000",
    "build": "vite build",
    "preview": "vite preview --host 0.0.0.0 --port 3000"
  },
  "dependencies": {
    "axios": "^1.9.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.5.0",
    "vite": "^5.4.19"
  }
}
EOF

cat > vite.config.js <<'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()]
})
EOF

cat > index.html <<'EOF'
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Expense Tracker</title>
    <script>
      window.API_URL = "http://localhost:8080/api";
    </script>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

cat > src/main.jsx <<'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './styles.css';

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
EOF

cat > src/api.js <<'EOF'
import axios from 'axios';

const api = axios.create({
  baseURL: window.API_URL || 'http://localhost:8080/api'
});

api.interceptors.request.use(config => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export default api;
EOF

cat > src/styles.css <<'EOF'
* { box-sizing: border-box; }
body { margin: 0; font-family: Arial, sans-serif; background: #f6f8fb; color: #111827; }
.container { max-width: 1100px; margin: 0 auto; padding: 24px; }
.card { background: #fff; border-radius: 12px; padding: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.08); margin-bottom: 20px; }
input, select, button { padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; }
input, select { width: 100%; }
button { background: #2563eb; color: white; cursor: pointer; border: none; }
button.secondary { background: #6b7280; }
.grid { display: grid; gap: 16px; }
.grid-2 { grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); }
.row { display: flex; gap: 12px; align-items: center; }
.space-between { display: flex; justify-content: space-between; align-items: center; }
table { width: 100%; border-collapse: collapse; }
th, td { text-align: left; padding: 10px; border-bottom: 1px solid #e5e7eb; }
h1, h2 { margin-top: 0; }
.error { color: #dc2626; margin-top: 8px; }
.success { color: #16a34a; margin-top: 8px; }
.stat { font-size: 28px; font-weight: bold; }
EOF

cat > src/App.jsx <<'EOF'
import React, { useEffect, useState } from 'react';
import api from './api';

function Login({ onLogin }) {
  const [isRegister, setIsRegister] = useState(false);
  const [form, setForm] = useState({
    fullName: 'Ayush Kumar',
    email: 'ayush@example.com',
    password: 'password123',
    currencyCode: 'INR'
  });
  const [error, setError] = useState('');

  const submit = async e => {
    e.preventDefault();
    setError('');
    try {
      const url = isRegister ? '/auth/register' : '/auth/login';
      const payload = isRegister ? form : { email: form.email, password: form.password };
      const res = await api.post(url, payload);
      localStorage.setItem('token', res.data.data.token);
      onLogin();
    } catch (err) {
      setError(err.response?.data?.message || 'Request failed');
    }
  };

  return (
    <div className="container">
      <div className="card" style={{maxWidth: 450, margin: '40px auto'}}>
        <h1>Expense Tracker</h1>
        <form onSubmit={submit} className="grid">
          {isRegister && <input placeholder="Full Name" value={form.fullName} onChange={e => setForm({...form, fullName: e.target.value})} />}
          <input placeholder="Email" value={form.email} onChange={e => setForm({...form, email: e.target.value})} />
          <input type="password" placeholder="Password" value={form.password} onChange={e => setForm({...form, password: e.target.value})} />
          {isRegister && <input placeholder="Currency Code" value={form.currencyCode} onChange={e => setForm({...form, currencyCode: e.target.value})} />}
          <button type="submit">{isRegister ? 'Register' : 'Login'}</button>
        </form>
        <p>
          <button className="secondary" onClick={() => setIsRegister(!isRegister)}>
            {isRegister ? 'Switch to Login' : 'Switch to Register'}
          </button>
        </p>
        {error && <div className="error">{error}</div>}
      </div>
    </div>
  );
}

function Dashboard({ onLogout }) {
  const [summary, setSummary] = useState(null);
  const [categories, setCategories] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [tx, setTx] = useState({
    categoryId: '',
    type: 'EXPENSE',
    amount: '',
    description: '',
    transactionDate: new Date().toISOString().slice(0,10),
    paymentMode: 'UPI',
    isRecurring: false
  });
  const [message, setMessage] = useState('');

  const load = async () => {
    const [catRes, txRes, dashRes] = await Promise.all([
      api.get('/categories'),
      api.get('/transactions'),
      api.get('/transactions/dashboard')
    ]);
    setCategories(catRes.data.data);
    setTransactions(txRes.data.data);
    setSummary(dashRes.data.data);
  };

  useEffect(() => { load().catch(console.error); }, []);

  const addTransaction = async e => {
    e.preventDefault();
    setMessage('');
    try {
      await api.post('/transactions', {
        ...tx,
        amount: Number(tx.amount),
        categoryId: tx.categoryId || null
      });
      setTx({...tx, amount: '', description: ''});
      setMessage('Transaction added successfully.');
      await load();
    } catch (err) {
      setMessage(err.response?.data?.message || 'Failed to add transaction.');
    }
  };

  const addDefaultCategories = async () => {
    const defaults = [
      { name: 'Food', type: 'EXPENSE' },
      { name: 'Salary', type: 'INCOME' },
      { name: 'Rent', type: 'EXPENSE' }
    ];
    for (const c of defaults) {
      try { await api.post('/categories', c); } catch {}
    }
    await load();
  };

  return (
    <div className="container">
      <div className="space-between">
        <h1>Expense Tracker Dashboard</h1>
        <button className="secondary" onClick={() => { localStorage.removeItem('token'); onLogout(); }}>Logout</button>
      </div>

      {!categories.length && (
        <div className="card">
          <p>No categories found.</p>
          <button onClick={addDefaultCategories}>Create Default Categories</button>
        </div>
      )}

      {summary && (
        <div className="grid grid-2">
          <div className="card"><h2>Income</h2><div className="stat">₹ {summary.totalIncome}</div></div>
          <div className="card"><h2>Expense</h2><div className="stat">₹ {summary.totalExpense}</div></div>
          <div className="card"><h2>Balance</h2><div className="stat">₹ {summary.balance}</div></div>
        </div>
      )}

      <div className="card">
        <h2>Add Transaction</h2>
        <form onSubmit={addTransaction} className="grid grid-2">
          <select value={tx.categoryId} onChange={e => setTx({...tx, categoryId: e.target.value})}>
            <option value="">Select Category</option>
            {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
          <select value={tx.type} onChange={e => setTx({...tx, type: e.target.value})}>
            <option value="EXPENSE">EXPENSE</option>
            <option value="INCOME">INCOME</option>
          </select>
          <input type="number" step="0.01" placeholder="Amount" value={tx.amount} onChange={e => setTx({...tx, amount: e.target.value})} />
          <input placeholder="Description" value={tx.description} onChange={e => setTx({...tx, description: e.target.value})} />
          <input type="date" value={tx.transactionDate} onChange={e => setTx({...tx, transactionDate: e.target.value})} />
          <select value={tx.paymentMode} onChange={e => setTx({...tx, paymentMode: e.target.value})}>
            {['CASH','UPI','CARD','BANK_TRANSFER','WALLET','OTHER'].map(p => <option key={p} value={p}>{p}</option>)}
          </select>
          <button type="submit">Save Transaction</button>
        </form>
        {message && <div className="success">{message}</div>}
      </div>

      <div className="card">
        <h2>Recent Transactions</h2>
        <table>
          <thead>
            <tr>
              <th>Date</th><th>Category</th><th>Type</th><th>Amount</th><th>Description</th>
            </tr>
          </thead>
          <tbody>
            {transactions.map(t => (
              <tr key={t.id}>
                <td>{t.transactionDate}</td>
                <td>{t.categoryName}</td>
                <td>{t.type}</td>
                <td>₹ {t.amount}</td>
                <td>{t.description}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default function App() {
  const [loggedIn, setLoggedIn] = useState(!!localStorage.getItem('token'));
  return loggedIn
    ? <Dashboard onLogout={() => setLoggedIn(false)} />
    : <Login onLogin={() => setLoggedIn(true)} />;
}
EOF

cat > README.md <<'EOF'
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
EOF

echo "Installing dependencies..."
npm install

echo ""
echo "✅ Frontend created successfully in: $(pwd)"
echo ""
echo "Run:"
echo "  cd $BASE_DIR"
echo "  npm run dev"
echo ""
echo "Open: http://localhost:3000"
echo "Backend API: http://localhost:8080/api"
echo "Note: PostgreSQL port 5433 is configured in your backend application.yml."

