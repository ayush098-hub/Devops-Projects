#!/usr/bin/env bash
set -e

PROJECT_DIR="${1:-expense-tracker-backend}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Project directory '$PROJECT_DIR' not found."
  echo "Usage: $0 /path/to/expense-tracker-backend"
  exit 1
fi

cd "$PROJECT_DIR"

mkdir -p src/main/java/com/example/expensetracker/service

cat > src/main/java/com/example/expensetracker/service/TransactionService.java <<'EOF'
package com.example.expensetracker.service;

// NOTE: This patch file is intentionally minimal.
// Replace with the full TransactionService content provided in chat if needed.
public class TransactionService {
}
EOF

echo "Patch scaffold created."
echo "IMPORTANT: This script is a placeholder patch scaffold."
echo "Use the full file contents from the chat to overwrite affected files."
echo "Then run:"
echo "  mvn clean package"

