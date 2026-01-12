# GFOS Digital Idea Board - Development Guide

## Preventing Common Issues - Best Practices

This guide outlines best practices to prevent issues like the password hash mismatch and ensure reliable development and deployment.

---

## Table of Contents

1. [Database Management](#database-management)
2. [Testing Strategy](#testing-strategy)
3. [Development Workflow](#development-workflow)
4. [Validation and Health Checks](#validation-and-health-checks)
5. [Error Handling and Logging](#error-handling-and-logging)
6. [Continuous Integration](#continuous-integration)
7. [Troubleshooting](#troubleshooting)

---

## 1. Database Management

### Always Validate Seed Data

**Problem**: The database initialization script had incorrect BCrypt password hashes.

**Solution**:
```bash
# After database initialization, ALWAYS run validation
cd backend
mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"
```

This utility tests:
- ✓ User credentials work correctly
- ✓ Password hashes verify with BCrypt
- ✓ All tables have seed data
- ✓ Data integrity constraints are met

### Generating Password Hashes

**Never** hardcode password hashes. Always generate them using the application's PasswordUtil:

```bash
# Generate correct BCrypt hashes
cd backend
mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.PasswordHashGenerator"
```

### Database Reset Procedure

If you need to reset the database:

1. Drop and recreate database:
   ```sql
   DROP DATABASE IF EXISTS ideaboard;
   CREATE DATABASE ideaboard OWNER ideaboard_user;
   ```

2. Run initialization script:
   ```bash
   psql -U ideaboard_user -h localhost -d ideaboard -f database/init.sql
   ```

3. **ALWAYS validate** after initialization:
   ```bash
   cd backend
   mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"
   ```

---

## 2. Testing Strategy

### Integration Tests

Integration tests verify the entire system works together correctly.

**Run authentication tests:**
```bash
cd backend
mvn test -Dtest=AuthenticationIntegrationTest
```

**Location**: `backend/src/test/java/com/gfos/ideaboard/integration/`

These tests verify:
- ✓ Database connection works
- ✓ User accounts exist
- ✓ Password verification works
- ✓ BCrypt hashes are correct
- ✓ Invalid passwords are rejected

### Testing Checklist Before Deployment

- [ ] Run database validation: `mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"`
- [ ] Run integration tests: `mvn test`
- [ ] Test login via API: `curl -X POST http://localhost:8080/ideaboard/api/auth/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}'`
- [ ] Test frontend login at http://localhost:3000
- [ ] Check GlassFish logs for errors

---

## 3. Development Workflow

### Before Committing Code

1. **Test your changes**
   ```bash
   mvn clean test
   ```

2. **Validate database if you changed schema or seed data**
   ```bash
   mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"
   ```

3. **Check for errors in logs**
   - Backend: `glassfish7/glassfish/domains/domain1/logs/server.log`
   - Frontend: Browser console and terminal

4. **Test the full user flow**
   - Login
   - Create/view ideas
   - Test permissions by role

### Code Review Checklist

- [ ] Are password hashes generated using PasswordUtil?
- [ ] Are there tests for new features?
- [ ] Is error logging added for failure cases?
- [ ] Are configuration values externalized (not hardcoded)?
- [ ] Does the code handle edge cases and validation?

---

## 4. Validation and Health Checks

### Automated Validation Tools

| Tool | Purpose | When to Run |
|------|---------|-------------|
| `ValidateDatabase` | Verify database seed data | After DB init, before deployment |
| `PasswordHashGenerator` | Generate BCrypt hashes | When adding new test users |
| `AuthenticationIntegrationTest` | Test login system | Before every deployment |

### Application Health Check

Add this to your deployment checklist:

```bash
# 1. Check database connectivity
psql -U ideaboard_user -h localhost -d ideaboard -c "SELECT COUNT(*) FROM users;"

# 2. Check GlassFish is running
curl http://localhost:8080/ideaboard/api/ideas

# 3. Check frontend can connect to backend
curl http://localhost:3000

# 4. Verify authentication
curl -X POST http://localhost:8080/ideaboard/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

---

## 5. Error Handling and Logging

### Logging Best Practices

The application now includes comprehensive logging:

**Authentication events are logged:**
- `INFO`: Successful logins
- `WARN`: Failed login attempts
- `DEBUG`: Login attempt details

**Check logs for issues:**
```bash
# GlassFish server log
tail -f "C:/glassfish-7.1.0/glassfish7/glassfish/domains/domain1/logs/server.log"
```

### Common Error Patterns

| Error | Cause | Solution |
|-------|-------|----------|
| "Invalid username or password" | Wrong credentials OR bad password hash | Run ValidateDatabase, check init.sql hashes |
| "Account is deactivated" | User's is_active=false | Check database: `SELECT * FROM users WHERE username='...'` |
| 401 Unauthorized | Token expired or invalid | Clear localStorage, login again |
| Database connection failed | PostgreSQL not running | Start PostgreSQL service |
| JDBC pool error | Wrong database credentials | Check glassfish JDBC configuration |

### Debugging Authentication Issues

```bash
# 1. Check user exists
psql -U ideaboard_user -d ideaboard -c "SELECT username, is_active FROM users WHERE username='admin';"

# 2. Test password hash manually
cd backend
mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.PasswordHashGenerator"

# 3. Check GlassFish logs for detailed error
grep -i "auth" glassfish7/glassfish/domains/domain1/logs/server.log

# 4. Run validation
mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"
```

---

## 6. Continuous Integration

### Recommended CI/CD Pipeline

```yaml
# Example GitHub Actions / GitLab CI pipeline

stages:
  - build
  - test
  - validate
  - deploy

build:
  script:
    - mvn clean package -DskipTests

test:
  script:
    - mvn test

validate_database:
  script:
    - psql -f database/init.sql
    - mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"

integration_tests:
  script:
    - mvn test -Dtest=AuthenticationIntegrationTest

deploy:
  script:
    - ./start-project.ps1
    - # Run smoke tests
```

### Pre-commit Hooks

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
echo "Running pre-commit checks..."

# Run tests
mvn test || {
    echo "Tests failed! Commit aborted."
    exit 1
}

echo "All checks passed!"
```

---

## 7. Troubleshooting

### Quick Diagnostic Commands

```bash
# Check all services are running
netstat -an | findstr "8080 3000 5432"

# Database user count
psql -U ideaboard_user -d ideaboard -c "SELECT COUNT(*) FROM users;"

# Test admin login API
curl -X POST http://localhost:8080/ideaboard/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"admin\",\"password\":\"admin123\"}"

# Check GlassFish deployment status
asadmin list-applications
```

### Common Issues and Solutions

#### Issue: "Cannot login with admin/admin123"

**Diagnosis:**
```bash
cd backend
mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"
```

**Solutions:**
1. If validation fails, password hashes are wrong:
   ```bash
   mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.FixPasswordHashes"
   ```

2. If user doesn't exist, reinitialize database:
   ```bash
   psql -U ideaboard_user -d ideaboard -f database/init.sql
   ```

#### Issue: "Tests passing but login still fails"

**Check frontend is hitting correct backend:**
```javascript
// frontend/vite.config.ts
proxy: {
  '/api': {
    target: 'http://localhost:8080/ideaboard',  // ← Must match backend URL
    changeOrigin: true,
  },
}
```

**Verify API endpoint:**
```bash
# Should return JWT token
curl -X POST http://localhost:8080/ideaboard/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

#### Issue: "Database validation fails"

1. Check PostgreSQL is running
2. Verify database credentials in validation script
3. Ensure database has been initialized: `psql -f database/init.sql`
4. Check database grants: `GRANT ALL ON DATABASE ideaboard TO ideaboard_user;`

---

## Summary: Prevention Checklist

✅ **Before Coding:**
- Pull latest code
- Run `start-project.ps1` to verify environment

✅ **During Development:**
- Write tests for new features
- Add logging for error conditions
- Use validation utilities for database changes

✅ **Before Committing:**
- Run `mvn test`
- Run `ValidateDatabase` if database changed
- Test manually in browser
- Check for errors in logs

✅ **Before Deployment:**
- All tests pass
- Database validation passes
- API tests pass (curl commands)
- Frontend connects successfully
- Documentation updated

✅ **After Deployment:**
- Run smoke tests
- Monitor logs for errors
- Verify user can login
- Check all critical features work

---

## Quick Reference

```bash
# Start application
.\start-project.ps1

# Validate database
cd backend && mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"

# Run tests
cd backend && mvn test

# Fix password hashes
cd backend && mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.FixPasswordHashes"

# Generate password hashes
cd backend && mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.PasswordHashGenerator"

# Test login API
curl -X POST http://localhost:8080/ideaboard/api/auth/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}'

# Check logs
tail -f glassfish7/glassfish/domains/domain1/logs/server.log
```

---

## Getting Help

If you encounter issues:

1. Check this guide's troubleshooting section
2. Run `ValidateDatabase` to identify the problem
3. Check GlassFish logs for detailed errors
4. Review the test results: `mvn test`
5. Verify configuration matches this guide

**Remember**: Most issues can be prevented by running validation tools after making changes!
