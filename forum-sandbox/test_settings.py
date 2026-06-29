# =============================================================================
# forum-sandbox/test_settings.py — Django settings for CI/CD tests
#
# Usage:
#   python manage.py test --settings=forum-sandbox.test_settings
#
# What this file does:
#   1. Sets dummy env vars so python-decouple does not raise errors
#   2. Imports all settings from the base module (forum-sandbox.settings)
#   3. Overrides DATABASES to SQLite in-memory — no PostgreSQL needed
#
# Note: module name has a hyphen, so standard `import` doesn't work.
#       importlib.import_module handles this correctly.
# =============================================================================
import os
import importlib

# ---------------------------------------------------------------------------
# Dummy env vars — base settings uses python-decouple config() which raises
# UndefinedValueError if a var is missing and has no default.
# These values are NOT real secrets — tests use SQLite and skip real services.
# ---------------------------------------------------------------------------
os.environ.setdefault("SECRET_KEY",           "ci-test-secret-key-not-for-production")
os.environ.setdefault("PG_DB",                "dummy")
os.environ.setdefault("PG_USER",              "dummy")
os.environ.setdefault("PG_PASSWORD",          "dummy")
os.environ.setdefault("DB_HOST",              "localhost")
os.environ.setdefault("DB_PORT",              "5432")
os.environ.setdefault("CORS_ORIGIN_WHITELIST","http://localhost")
os.environ.setdefault("EMAIL_BACKEND",        "django.core.mail.backends.console.EmailBackend")
os.environ.setdefault("EMAIL_HOST",           "localhost")
os.environ.setdefault("EMAIL_PORT",           "587")
os.environ.setdefault("EMAIL_USE_TLS",        "1")
os.environ.setdefault("EMAIL_HOST_USER",      "ci@example.com")
os.environ.setdefault("EMAIL_HOST_PASSWORD",  "dummy")

# ---------------------------------------------------------------------------
# Import base settings (hyphen in module name requires importlib)
# ---------------------------------------------------------------------------
_base = importlib.import_module("forum-sandbox.settings")
for _key in dir(_base):
    if _key.isupper():
        globals()[_key] = getattr(_base, _key)

# ---------------------------------------------------------------------------
# Override: SQLite in-memory — fast, no server, no credentials needed
# ---------------------------------------------------------------------------
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME":   ":memory:",
    }
}
