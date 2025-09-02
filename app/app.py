#!/usr/bin/env python3
"""
Hello World Flask Application
A simple web app demonstrating Artifact Registry and GKE deployment
"""

from flask import Flask, jsonify, render_template_string
import os
import socket
import datetime

app = Flask(__name__)

# Get environment information
ENVIRONMENT = os.getenv('ENVIRONMENT', 'development')
VERSION = os.getenv('APP_VERSION', '1.0.0')
HOSTNAME = socket.gethostname()

# HTML template for the web interface
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello World - Flask App</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
            padding: 20px;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            text-align: center;
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
            max-width: 600px;
        }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .emoji {
            font-size: 4em;
            margin: 20px 0;
        }
        .info {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
            text-align: left;
        }
        .info-item {
            margin: 10px 0;
            padding: 8px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 5px;
        }
        .label {
            font-weight: bold;
            color: #ffd700;
        }
        .status {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: bold;
        }
        .env-development { background: #28a745; }
        .env-staging { background: #ffc107; color: #000; }
        .env-production { background: #dc3545; }
        .api-link {
            display: inline-block;
            margin: 10px;
            padding: 10px 20px;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            text-decoration: none;
            border-radius: 25px;
            transition: all 0.3s ease;
        }
        .api-link:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-2px);
        }
        .footer {
            margin-top: 30px;
            font-size: 0.9em;
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="emoji"></div>
        <h1>Hello, World!</h1>
        <p>Welcome to your Flask app running on Google Kubernetes Engine!</p>
        
        <div class="info">
            <h3> Application Info</h3>
            <div class="info-item">
                <span class="label">Environment:</span> 
                <span class="status env-{{ environment.lower() }}">{{ environment }}</span>
            </div>
            <div class="info-item">
                <span class="label">Version:</span> {{ version }}
            </div>
            <div class="info-item">
                <span class="label">Hostname:</span> {{ hostname }}
            </div>
            <div class="info-item">
                <span class="label">Current Time:</span> {{ current_time }}
            </div>
            <div class="info-item">
                <span class="label">Container Registry:</span> Google Artifact Registry
            </div>
            <div class="info-item">
                <span class="label">Orchestration:</span> Google Kubernetes Engine (GKE)
            </div>
        </div>

        <div class="info">
            <h3> API Endpoints</h3>
            <a href="/api/health" class="api-link">Health Check</a>
            <a href="/api/info" class="api-link">App Info (JSON)</a>
            <a href="/api/version" class="api-link">Version</a>
        </div>

        <div class="footer">
            <p> Successfully deployed from Artifact Registry to GKE!</p>
            <p>Built with  using Python Flask, Docker, Terraform & Terragrunt</p>
        </div>
    </div>
</body>
</html>
"""

@app.route('/')
def hello_world():
    """Main page with web interface"""
    return render_template_string(
        HTML_TEMPLATE,
        environment=ENVIRONMENT,
        version=VERSION,
        hostname=HOSTNAME,
        current_time=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
    )

@app.route('/api/health')
def health_check():
    """Health check endpoint for Kubernetes"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.datetime.now().isoformat(),
        'hostname': HOSTNAME,
        'environment': ENVIRONMENT
    })

@app.route('/api/info')
def app_info():
    """Application information endpoint"""
    return jsonify({
        'app_name': 'Hello World Flask App',
        'version': VERSION,
        'environment': ENVIRONMENT,
        'hostname': HOSTNAME,
        'python_version': os.sys.version,
        'flask_version': '2.3.3',
        'timestamp': datetime.datetime.now().isoformat(),
        'container_info': {
            'registry': 'Google Artifact Registry',
            'orchestration': 'Google Kubernetes Engine (GKE)',
            'infrastructure': 'Terraform + Terragrunt'
        }
    })

@app.route('/api/version')
def version():
    """Version endpoint"""
    return jsonify({
        'version': VERSION,
        'environment': ENVIRONMENT,
        'build_time': datetime.datetime.now().isoformat()
    })

@app.route('/api/hello/<name>')
def hello_name(name):
    """Personalized hello endpoint"""
    return jsonify({
        'message': f'Hello, {name}!',
        'hostname': HOSTNAME,
        'environment': ENVIRONMENT,
        'timestamp': datetime.datetime.now().isoformat()
    })

if __name__ == '__main__':
    # Get port from environment variable or default to 5000
    port = int(os.getenv('PORT', 5000))
    
    print(f" Starting Hello World Flask App")
    print(f" Environment: {ENVIRONMENT}")
    print(f"  Version: {VERSION}")
    print(f"  Hostname: {HOSTNAME}")
    print(f" Port: {port}")
    
    # Run the app
    app.run(
        host='0.0.0.0',
        port=port,
        debug=(ENVIRONMENT == 'development')
    )
