from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'user-service'})

@app.route('/api/users')
def get_users():
    users = [{'id': 1, 'name': 'Admin'}]
    
    if os.getenv('FEATURE_NEW_UI', 'false').lower() == 'true':
        users[0]['role'] = 'SuperAdmin'
        users[0]['badge'] = 'Early Access'
        
    return jsonify({'users': users})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)