# Expense Tracker Backend

## Prerequisites
- Java 17+
- Maven 3.8+
- PostgreSQL with expense_tracker schema (run the DDL first)

## Run
1. Update `src/main/resources/application.yml` with your DB credentials.
2. Build and start:
   ```bash
   mvn clean package -DskipTests
   mvn spring-boot:run
   ```

## API endpoints
| Method | Path | Notes |
|--------|------|-------|
| POST | /api/auth/register | Register user |
| POST | /api/auth/login | Login → returns JWT |
| GET  | /api/categories | List categories |
| POST | /api/categories | Create category |
| GET  | /api/transactions | List transactions |
| POST | /api/transactions | Create transaction |
| GET  | /api/transactions/dashboard?from=YYYY-MM-DD&to=YYYY-MM-DD | Dashboard summary |
| GET  | /api/budgets?month=5&year=2026 | List budgets |
| POST | /api/budgets | Create budget |
| GET  | /api/tags | List tags |
| POST | /api/tags | Create tag |
| GET  | /api/recurring-rules | List recurring rules |
| POST | /api/recurring-rules | Create recurring rule |

## Bugs fixed vs previous version
1. **dashboard 500** — PostgreSQL enum casting error (`'EXPENSE'::TransactionType` → type not found in public schema).
   Fix: JPQL queries now pass enums as Java parameters (`:type`) so Hibernate binds them correctly.
2. **GET /api/budgets 500** — `could not initialize proxy Category - no Session`.
   Fix: `Budget.category` changed to `FetchType.EAGER` + `BudgetService.list()` annotated `@Transactional(readOnly=true)`.
3. **GET /api/recurring-rules 500** — same lazy-loading issue.
   Fix: `RecurringRule.category` changed to `FetchType.EAGER` + `RecurringRuleService.list()` annotated `@Transactional(readOnly=true)`.
4. **dashboard null date param** — `could not determine data type of parameter $3`.
   Fix: JPQL null guard `(:from is null or ...)` with proper Hibernate binding avoids untyped NULL in native SQL.
