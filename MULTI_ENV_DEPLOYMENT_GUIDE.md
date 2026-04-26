# Multi-Environment Deployment Guide

## 📋 Overview

The LMS now supports three environments:
- **Production (main)**: http://98.92.14.139/ → Port 8000
- **UAT**: http://98.92.14.139/uat/ → Port 8001
- **Develop**: http://98.92.14.139/develop/ → Port 8002

Each environment has:
- ✓ Separate `.env` file (`.env.main`, `.env.uat`, `.env.develop`)
- ✓ Separate GitHub Actions deployment workflow
- ✓ Separate gunicorn instance on different port
- ✓ Separate static files directory
- ✓ Environment-aware Django settings

---

## 🔧 Environment Configuration Files

### File Structure
```
.env.main       → Production environment
.env.uat        → UAT environment  
.env.develop    → Development environment
```

### Key Differences

| Variable | Main (Prod) | UAT | Develop |
|----------|-------------|-----|---------|
| `DEBUG` | `False` | `False` | `True` |
| `APP_PORT` | `8000` | `8001` | `8002` |
| `ENVIRONMENT` | `main` | `uat` | `develop` |
| `STATIC_URL` | `/static/` | `/uat/static/` | `/develop/static/` |
| `MEDIA_URL` | `/media/` | `/uat/media/` | `/develop/media/` |
| `ALLOWED_HOSTS` | `98.92.14.139` | `98.92.14.139` | `127.0.0.1,localhost,98.92.14.139` |

### Update Environment Variables

Before deployment, update these files with your actual values:
- `SECRET_KEY` - Generate a strong secret for each environment
- `EMAIL_HOST_USER` / `EMAIL_HOST_PASSWORD` - For email functionality
- `STRIPE_SECRET_KEY` / `STRIPE_PUBLISHABLE_KEY` - For payment processing

**For Production:** Store sensitive values in GitHub Secrets instead of committing to `.env.main`

---

## 🚀 Branching Strategy

### Git Branches

```
main ← UAT (PR + Approval Required)
  ↓
  └─ Production Deployment (via deploy.yml)
    
uat ← Develop (Regular commits)
  ↓
  └─ UAT Deployment (via deploy-uat.yml)
  
develop (Regular development)
  ↓
  └─ Develop Deployment (via deploy-develop.yml)
```

### Workflow

1. **Develop Environment** (Branch: `develop`)
   - Push to `develop` → Auto-deploys to http://98.92.14.139/develop/
   - GitHub Actions: `.github/workflows/deploy-develop.yml`
   - Used for: Early development, feature testing

2. **UAT Environment** (Branch: `uat`)
   - Push to `uat` → Auto-deploys to http://98.92.14.139/uat/
   - GitHub Actions: `.github/workflows/deploy-uat.yml`
   - Used for: User acceptance testing, staging

3. **Production Environment** (Branch: `main`)
   - Pull Request from `uat` → Runs validation tests
   - Approval required from maintainers
   - Merge to `main` → Auto-deploys to http://98.92.14.139/
   - GitHub Actions: `.github/workflows/deploy.yml` (renamed from deploy.yml)
   - Used for: Production release

---

## 📝 Making Changes & Creating PR

### Step 1: Create Feature Branch (from develop)
```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature
# Make your changes
git add .
git commit -m "feat: add new feature"
git push origin feature/my-feature
```

### Step 2: Test in Develop Environment
- Push changes to `develop`
- GitHub Actions automatically deploys to `http://98.92.14.139/develop/`
- Check logs in Actions tab if deployment fails
- Verify feature works at the develop endpoint

### Step 3: Create PR from Develop to UAT
```bash
git checkout uat
git pull origin uat
git merge develop
# Resolve conflicts if any
git push origin uat
```
Or use GitHub's web UI to create PR from `develop` branch to `uat` branch
- GitHub Actions automatically deploys to `http://98.92.14.139/uat/`

### Step 4: Test in UAT Environment
- URL: http://98.92.14.139/uat/
- Perform user acceptance testing
- Verify all features work in non-debug mode (DEBUG=False)
- Check server logs if issues occur

### Step 5: Create PR from UAT to Main
```bash
# Option A: Via command line
git checkout main
git pull origin main
git merge uat
git push origin main

# Option B: Via GitHub Web UI (Recommended)
# Go to GitHub repo → Pull Requests → New Pull Request
# Base: main | Compare: uat
# Add description and create PR
```

When PR is created:
- GitHub Actions runs: `.github/workflows/pr-uat-to-main.yml`
- Tests are executed
- Linting is performed
- Comments added with validation results

### Step 6: Review & Approve PR
- Assign reviewers
- Wait for CI checks to pass
- Resolve any conflicts
- Request changes if needed
- Approve when ready

### Step 7: Merge & Deploy to Production
- Click "Merge pull request" on GitHub
- GitHub Actions automatically deploys to `http://98.92.14.139/ (main)`
- Smoke tests run to verify deployment
- Monitor production for any issues

---

## 🔍 Verification Steps

### Verify Local Setup
```bash
# Load environment variables
export $(cat .env.develop | xargs)

# Run Django checks
python manage.py check

# Build static files
python manage.py collectstatic --noinput

# Run tests
python manage.py test
```

### Verify Endpoints After Deployment

```bash
# Production endpoint
curl -v http://98.92.14.139/

# UAT endpoint
curl -v http://98.92.14.139/uat/

# Develop endpoint
curl -v http://98.92.14.139/develop/

# Check static files are served
curl -v http://98.92.14.139/static/css/style.css
curl -v http://98.92.14.139/uat/static/css/style.css
curl -v http://98.92.14.139/develop/static/css/style.css

# Check login pages (expected: 200 OK or 302 redirect)
curl -L -v http://98.92.14.139/ | head -n 50
curl -L -v http://98.92.14.139/uat/ | head -n 50
curl -L -v http://98.92.14.139/develop/ | head -n 50
```

### Expected Response Codes
- **200**: HTML page returned
- **302**: Redirect to login (expected for `/` without authentication)
- **400-599**: Deployment failed, check logs

---

## 📊 GitHub Actions Workflows

### 1. Deploy Develop (`deploy-develop.yml`)
- **Triggers**: Push to `develop` branch
- **Steps**:
  - Fetch latest code from `develop`
  - Install dependencies
  - Run Django checks
  - Run migrations
  - Collect static files (to `staticfiles-develop/`)
  - Start gunicorn on port 8002
  - Restart nginx
  - Run smoke tests
- **Access**: http://98.92.14.139/develop/

### 2. Deploy UAT (`deploy-uat.yml`)
- **Triggers**: Push to `uat` branch
- **Steps**: Same as develop
- **Key Differences**:
  - Runs with `DEBUG=False` (production-like)
  - Gunicorn on port 8001
  - Static files to `staticfiles-uat/`
- **Access**: http://98.92.14.139/uat/

### 3. Deploy Production (`deploy.yml`)
- **Triggers**: Push to `main` branch (typically after PR merge)
- **Steps**: Same as others
- **Key Differences**:
  - Highest scrutiny (should only happen after PR approval)
  - Gunicorn on port 8000
  - Static files to `staticfiles/`
- **Access**: http://98.92.14.139/

### 4. PR Validation (`pr-uat-to-main.yml`)
- **Triggers**: PR opened/updated targeting `main` from `uat`
- **Steps**:
  - Run full test suite
  - Run Django checks
  - Run pylint
  - Comment PR with results
- **Purpose**: Catch issues before production

---

## 🐛 Troubleshooting

### Deployment Fails with "HTTP 400/500"

Run local test with environment enabled:
```bash
export $(cat .env.main | xargs)
DEBUG=False python manage.py runserver
```

Check error logs on server:
```bash
# SSH to EC2
ssh -i your-key.pem ec2-user@98.92.14.139

# Check gunicorn logs
sudo tail -f /var/log/gunicorn/error.log
sudo tail -f /var/log/gunicorn/uat-error.log
sudo tail -f /var/log/gunicorn/develop-error.log

# Check nginx logs
sudo tail -f /var/log/nginx/error.log

# Check gunicorn status
sudo ps aux | grep gunicorn
```

### Static Files Not Loading

```bash
# Verify nginx configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx

# Check if static files exist
ls -la /home/ec2-user/lms2/LMS/staticfiles/
ls -la /home/ec2-user/lms2/LMS/staticfiles-uat/
ls -la /home/ec2-user/lms2/LMS/staticfiles-develop/
```

### Endpoints Return 502 Bad Gateway

```bash
# Check gunicorn processes
sudo ps aux | grep gunicorn

# Check if ports are listening
sudo netstat -tlnp | grep 800

# Check nginx upstream configuration
sudo cat /etc/nginx/sites-enabled/lms | grep upstream
```

---

## 📋 Nginx Configuration

The nginx configuration file at `nginx-config-template.conf` handles path-based routing:
- `/` → Port 8000 (Production)
- `/uat/` → Port 8001 (UAT)
- `/develop/` → Port 8002 (Develop)

**Apply to server:**
```bash
# Copy template to nginx
sudo cp nginx-config-template.conf /etc/nginx/sites-available/lms
sudo ln -s /etc/nginx/sites-available/lms /etc/nginx/sites-enabled/lms

# Test configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

---

## 🔐 Security Notes

- **Production ('.env.main')**: Use GitHub Secrets for `SECRET_KEY`, API credentials
- **UAT ('.env.uat')**: Can be less restrictive, test environment
- **Develop ('.env.develop')**: Maximum flexibility, can use wildcard ALLOWED_HOSTS
- Always set `DEBUG=False` for UAT and Production
- Review nginx error logs for security issues

---

## ✅ Checklist for Initial Setup

- [ ] Update `.env.main` with production secrets (via GitHub Secrets in action)
- [ ] Update `.env.uat` with test secrets
- [ ] Update `.env.develop` for local dev testing
- [ ] Apply nginx configuration to EC2 server
- [ ] Create separate gunicorn service files or scripts for each port
- [ ] Verify each endpoint returns 200-399 (not 400+)
- [ ] Test PR workflow: develop → uat → main
- [ ] Configure GitHub branch protection rules:
  - Require PR reviews for `main`
  - Require status checks to pass before merge
  - Dismiss stale PR approvals

---

## 📞 Support

For deployment issues:
1. Check GitHub Actions logs (Settings → Actions)
2. SSH to server and check gunicorn/nginx logs
3. Run local tests with environment variables loaded
4. Review recent commits for configuration changes
