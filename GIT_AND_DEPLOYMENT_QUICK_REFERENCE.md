# Git & Deployment Quick Reference

## 🌿 Branch Strategy

```
main (Production)
  ↑ ← PR from uat (requires review + tests passing)
  |
uat (User Acceptance Test)
  ↑ ← PR from develop
  |
develop (Development)
  ↑ ← Feature branches
  |
feature/* (Feature branches)
```

---

## 🚀 Common Workflows

### **1. Start New Feature**
```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature-name

# Make your changes
git add .
git commit -m "feat: describe your feature"
git push origin feature/my-feature-name
```

### **2. Merge Feature to Develop (Get Code to Development Environment)**
```bash
# Option A: Via GitHub Web UI (Recommended for team)
# Go to: GitHub → Pull Requests → Create New
# Base: develop | Compare: feature/my-feature-name
# Create PR, wait for checks, merge

# Option B: Via Command Line
git checkout develop
git pull origin develop
git merge feature/my-feature-name
git push origin develop
# ✅ Auto-deploys to: http://98.92.14.139/develop/
```

### **3. Test in Develop Environment**
```bash
# Wait for GitHub Actions to deploy (2-3 minutes)
curl http://98.92.14.139/develop/
# Or visit in browser: http://98.92.14.139/develop/

# Check logs if deployment fails:
# Settings → Actions → Recent Runs → Click Failed Run
```

### **4. Promote to UAT (After Testing in Develop)**
```bash
# Option A: Via GitHub Web UI (Recommended)
# Create new PR: develop → uat
# Merge when ready

# Option B: Via Command Line
git checkout uat
git pull origin uat
git merge develop
git push origin uat
# ✅ Auto-deploys to: http://98.92.14.139/uat/
```

### **5. Test in UAT Environment**
```bash
# Wait for GitHub Actions to deploy
curl http://98.92.14.139/uat/
# Or visit in browser: http://98.92.14.139/uat/

# Full testing with DEBUG=False (production conditions)
```

### **6. Promote to Production (After UAT Approval)**
```bash
# Option A: Via GitHub Web UI (Recommended)
# Create new PR: uat → main
# Assign reviewers
# Wait for:
#   ✓ Tests pass
#   ✓ Django checks pass
#   ✓ Linting passes
# Review the PR
# Approve PR
# Merge PR (Squash or Merge as preferred)

# Option B: Via Command Line
git checkout main
git pull origin main
git merge uat
git push origin main
# ✅ Auto-deploys to: http://98.92.14.139/
```

### **7. Verify Production Deployment**
```bash
# Wait for GitHub Actions to deploy (2-3 minutes)
curl http://98.92.14.139/
# Or visit in browser: http://98.92.14.139/

# All three should now work:
curl http://98.92.14.139/                # Production
curl http://98.92.14.139/uat/            # UAT (still there)
curl http://98.92.14.139/develop/        # Develop (still there)
```

---

## 🔄 Hotfix Process (Emergency Production Fix)

### **If Bug Found in Production**

```bash
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug

# Fix the bug
git add .
git commit -m "fix: critical production bug"
git push origin hotfix/critical-bug

# Create PR directly to main (Emergency)
# GitHub → Pull Requests → Create New
# Base: main | Compare: hotfix/critical-bug
# Add label: HOTFIX
# Create PR, get IMMEDIATE review, merge

# Then backport to uat and develop
git checkout uat
git merge main
git push origin uat

git checkout develop
git merge main
git push origin develop
```

---

## 📊 Check Deployment Status

### **Via GitHub UI**
1. Go to: Settings → Actions
2. View recent workflow runs
3. Check status (✅ passed or ❌ failed)
4. Click failed run to see error logs

### **Via Command Line**
```bash
# See recent git commits
git log --oneline -10

# See which branch each environment is on
git branch -v

# See remote branches
git branch -r -v
```

### **Test Endpoints**
```bash
# Quick status check
echo "Production: $(curl -s -o /dev/null -w "%{http_code}" http://98.92.14.139/)"
echo "UAT:        $(curl -s -o /dev/null -w "%{http_code}" http://98.92.14.139/uat/)"
echo "Develop:    $(curl -s -o /dev/null -w "%{http_code}" http://98.92.14.139/develop/)"
```

---

## ⚠️ Important Notes

### **DO's ✅**
- Create feature branches from `develop`
- Use descriptive commit messages
- Create PRs for all changes
- Wait for CI checks to pass
- Require peer review for production PRs
- Test in each environment before promoting

### **DON'Ts ❌**
- Never push directly to `main` (branch protection prevents this)
- Never push directly to `uat` (for larger teams)
- Never skip PR reviews for production
- Never merge PR if tests are failing
- Never modify environment variables manually on server
- Never delete `develop`, `uat`, or `main` branches

---

## 🆘 If Deployment Fails

### **Failed Tests**
```bash
# Run tests locally
python manage.py test

# Check test output
pytest -v  # or your test runner

# Fix issues
git add .
git commit -m "fix: tests now passing"
git push  # PR automatically re-runs checks
```

### **Failed Django Checks**
```bash
# Check locally
export $(cat .env.develop | grep -v "^#" | xargs sed 's/^/export /')
python manage.py check

# Common issues:
# - Missing environment variables
# - Incorrect database configuration
# - Missing apps in INSTALLED_APPS
```

### **Failed Deployment**
```bash
# SSH to server
ssh -i key.pem ec2-user@98.92.14.139

# Check gunicorn errors
sudo tail -f /var/log/gunicorn/error.log
sudo tail -f /var/log/gunicorn/uat-error.log
sudo tail -f /var/log/gunicorn/develop-error.log

# Check nginx errors
sudo tail -f /var/log/nginx/error.log

# Restart services
sudo systemctl restart nginx
```

---

## 📱 Endpoint URLs

| Environment | Status | URL |
|---|---|---|
| **Production** | Live 🟢 | http://98.92.14.139/ |
| **UAT** | Staging 🟡 | http://98.92.14.139/uat/ |
| **Develop** | Dev 🔵 | http://98.92.14.139/develop/ |

---

## 📋 Best Practices

1. **Always pull before creating branches**
   ```bash
   git checkout develop && git pull
   ```

2. **Use meaningful branch names**
   ```bash
   ✅ feature/user-authentication
   ✅ bugfix/login-error-handling
   ✅ hotfix/database-connection
   ❌ feature/stuff
   ❌ fix/test
   ```

3. **Commit frequently with clear messages**
   ```
   ✅ feat: add two-factor authentication
   ✅ fix: resolve null pointer in user service
   ✅ docs: update API documentation
   ❌ update stuff
   ❌ fixes
   ```

4. **Always write descriptive PR descriptions**
   - What changed?
   - Why did it change?
   - How to test?
   - Any breaking changes?

5. **Review before merging**
   - Check code quality
   - Verify tests pass
   - Look for security issues
   - Ensure documentation is updated

---

## 🎖️ Team Role Responsibilities

### **Developer**
- Creates feature branches from `develop`
- Submits PRs to `develop`
- Runs tests locally before pushing
- Updates documentation as needed

### **QA/Tester**
- Tests in `develop` environment first
- Approves PR for merging to `uat`
- Performs user acceptance testing in `uat`
- Signs off on UAT before production merge

### **DevOps/Release Manager**
- Reviews code quality
- Approves merge to `uat`
- Approves final merge to `main`
- Monitors production deployment
- On-call for incident management

### **Tech Lead**
- Sets coding standards
- Reviews security aspects
- Handles hotfixes
- Makes architectural decisions

---

## ⏰ Typical Release Timeline

| Phase | Duration | Environment | Status |
|---|---|---|---|
| Feature Development | Variable | Local + `develop` | In Progress 🔷 |
| Testing in Develop | 1-2 days | `develop` | Testing 🧪 |
| UAT Approval | 2-5 days | `uat` | Approval 📋 |
| Production Merge | Same day | `main` | Deployment 🚀 |
| Production Verification | 1-2 hours | `main` | Live ✅ |

---

**Last Updated**: April 26, 2026  
**Version**: 1.0  
**Status**: Ready for Use
