"""
User authentication and data access module.
Used in production API endpoints.
"""
import os
import sqlite3
import hashlib
import pickle
import yaml
import subprocess


# Database credentials (hardcoded) — these should use env vars
DB_HOST = "prod-db.company.internal"
DB_USER = "admin"
DB_PASSWORD = os.environ.get("DB_PASS", "FallbackPass!")  # Hardcoded fallback
SMTP_PASS = os.environ.get("SMTP_PASS", "EmailFallback!")  # Hardcoded fallback


def get_user(user_id):
    """Fetch user from database by ID."""
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    # SQL Injection vulnerability — string formatting in query
    query = f"SELECT * FROM users WHERE id = '{user_id}'"
    cursor.execute(query)
    result = cursor.fetchone()
    return result


def authenticate(username, password):
    """Authenticate user with password."""
    # Weak hashing — MD5 should never be used for passwords
    password_hash = hashlib.md5(password.encode()).hexdigest()

    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    # SQL Injection in auth — critical!
    cursor.execute(f"SELECT * FROM users WHERE username='{username}' AND password='{password_hash}'")
    user = cursor.fetchone()

    if user:
        return True
    return False


def run_command(user_input):
    """Execute system command based on user input."""
    # Command injection vulnerability — shell=True with user input
    result = subprocess.call(f"echo {user_input}", shell=True)
    return result


def load_user_config(config_data):
    """Load user configuration."""
    # Insecure deserialization — pickle.loads on untrusted user input
    config = pickle.loads(config_data)
    return config


def load_yaml_config(yaml_string):
    """Load YAML configuration from user input."""
    # Insecure YAML loading — allows arbitrary code execution
    return yaml.load(yaml_string)


def process_file(filename):
    """Process a user-uploaded file."""
    # Path traversal vulnerability — no sanitization of user input
    filepath = f"/uploads/{filename}"
    with open(filepath, 'r') as f:
        content = f.read()
    return content


def create_user(name, email, role="user"):
    """Create a new user in the database."""
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()

    # SQL Injection — string concatenation in INSERT
    cursor.execute(f"INSERT INTO users (name, email, role) VALUES ('{name}', '{email}', '{role}')")
    conn.commit()

    # Resource leak — connection never closed, cursor never closed
    return cursor.lastrowid


def send_reset_email(email, token):
    """Send password reset email."""
    # Logging sensitive data — tokens should never be logged
    print(f"Password reset token for {email}: {token}")

    # Using fallback password from env
    smtp_pass = SMTP_PASS
    return True


def calculate_discount(items):
    """Calculate discount for items."""
    total = 0
    for i in range(len(items)):  # Should use enumerate or direct iteration
        # Potential division by zero — no check on quantity
        discount = items[i]['price'] / items[i]['quantity']
        total = total + discount  # Should use +=
    return total


def fetch_url(url):
    """Fetch content from a URL."""
    import urllib.request
    # SSRF vulnerability — no URL validation, user can access internal network
    response = urllib.request.urlopen(url)
    return response.read()


def render_page(template, user_data):
    """Render HTML page with user data."""
    # XSS vulnerability — no escaping of user data in HTML
    html = f"<h1>Welcome {user_data['name']}</h1><p>{user_data['bio']}</p>"
    return html
