#!/usr/bin/env python
"""
Test script to verify each environment configuration works with Django
Run: python test-environments.py
"""

import os
import sys
import django
from pathlib import Path

# Add project to path
BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

ENVIRONMENTS = ["develop", "uat", "main"]

def load_env_file(env_name):
    """Load environment file into os.environ"""
    env_file = f".env.{env_name}"
    if not os.path.exists(env_file):
        return False
    
    with open(env_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key.strip()] = value.strip()
    
    return True

def test_environment(env_name):
    """Test a specific environment"""
    print(f"\n{'='*60}")
    print(f"Testing {env_name.upper()} Environment")
    print(f"{'='*60}")
    
    # Load environment file
    if not load_env_file(env_name):
        print(f"❌ ERROR: .env.{env_name} not found")
        return False
    
    print(f"✓ Loaded .env.{env_name}")
    
    # Display environment values
    print(f"\n📋 Configuration:")
    print(f"  DEBUG: {os.getenv('DEBUG', 'not set')}")
    print(f"  ENVIRONMENT: {os.getenv('ENVIRONMENT', 'not set')}")
    print(f"  APP_PORT: {os.getenv('APP_PORT', 'not set')}")
    print(f"  STATIC_URL: {os.getenv('STATIC_URL', 'not set')}")
    print(f"  MEDIA_URL: {os.getenv('MEDIA_URL', 'not set')}")
    print(f"  ALLOWED_HOSTS: {os.getenv('ALLOWED_HOSTS', 'not set')}")
    
    # Setup Django
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    
    try:
        # Configure Django
        try:
            from django.apps import apps
            if not apps.ready:
                django.setup()
        except:
            django.setup()
        
        # Import after Django setup
        from django.conf import settings
        from django.core.management import call_command
        
        print(f"\n🔍 Running Django system checks...")
        call_command('check', verbosity=1)
        
        print(f"\n✅ Django Configuration (from settings.py):")
        print(f"  ENVIRONMENT: {settings.ENVIRONMENT}")
        print(f"  ENVIRONMENT_NAME: {settings.ENVIRONMENT_NAME}")
        print(f"  STATIC_URL: {settings.STATIC_URL}")
        print(f"  STATIC_ROOT: {settings.STATIC_ROOT}")
        print(f"  MEDIA_URL: {settings.MEDIA_URL}")
        print(f"  DEBUG: {settings.DEBUG}")
        
        print(f"\n✅ {env_name.upper()} environment is properly configured!")
        return True
        
    except Exception as e:
        print(f"\n❌ ERROR in {env_name} environment:")
        print(f"  {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Test all environments"""
    print(f"\n{'='*60}")
    print(f"LMS Multi-Environment Configuration Test")
    print(f"{'='*60}")
    
    results = {}
    for env in ENVIRONMENTS:
        results[env] = test_environment(env)
    
    print(f"\n{'='*60}")
    print(f"Test Summary")
    print(f"{'='*60}")
    
    for env, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{env:10s}: {status}")
    
    if all(results.values()):
        print(f"\n✅ All environments configured correctly!")
        return 0
    else:
        print(f"\n❌ Some environments failed verification")
        return 1

if __name__ == "__main__":
    sys.exit(main())
