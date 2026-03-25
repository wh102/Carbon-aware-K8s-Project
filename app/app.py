from flask import Flask, render_template, request, jsonify
from flask_mysqldb import MySQL
import os
import time
import requests
import signal
import sys
import socket

app = Flask(__name__)

# 1. Database Configuration (Uses Docker container name 'mysql' as default)
app.config['MYSQL_HOST'] = os.environ.get('MYSQL_HOST', 'mysql')
app.config['MYSQL_USER'] = os.environ.get('MYSQL_USER', 'root')
app.config['MYSQL_PASSWORD'] = os.environ.get('MYSQL_PASSWORD', 'admin')
app.config['MYSQL_DB'] = os.environ.get('MYSQL_DB', 'testdb')
app.config['MYSQL_PASSWORD'] = os.environ.get('MYSQL_PASSWORD', 'admin')


mysql = MySQL(app)

# 2. Database Initialization with Retry Loop (Crucial for t3.micro)
def init_db():
    for i in range(10):
        try:
            with app.app_context():
                cur = mysql.connection.cursor()
                cur.execute('''
                CREATE TABLE IF NOT EXISTS messages (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    message TEXT
                );
                ''')
                mysql.connection.commit()  
                cur.close()
            print("Successfully connected to MySQL and initialized DB!")
            return True
        except Exception as e:
            print(f"Waiting for MySQL... (Attempt {i+1}/10). Error: {e}")
            time.sleep(5)
    return False
    
def get_carbon_intensity():
    try:
        url = "https://api.carbonintensity.org.uk/intensity"
        headers = {'Accept': 'application/json'}
        
        response = requests.get(url, headers=headers, timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            return data['data'][0]['intensity']['index']
    except Exception as e:
        print(f"Error fetching carbon data: {e}")
    return "unknown"

def handle_sigterm(sig, frame):
    print("Received SIGTERM, shutting down gracefully...")
    try:
        mysql.connection.close()
        print("MySQL connections closed.")
    except Exception as e:
        print(f"Error during cleanup: {e}")      
    sys.exit(0)

signal.signal(signal.SIGETERM, handle_sigterm)

@app.route('/')
def hello():
    pod_name = socket.gethostname()
    intensity = get_carbon_intensity() 
    
    try:
        with mysql.connection.cursor() as cur:
            cur.execute('SELECT message FROM messages')
            messages = cur.fetchall()
        
        return render_template('index.html', messages=messages, intensity=intensity, pod_name=pod_name)
    except Exception as e:
        return render_template('index.html', messages=[], intensity=intensity, pod_name=pod_name, error=str(e))


@app.route('/submit', methods=['POST'])
def submit():
    new_message = request.form.get('new_message')
    try:
        cur = mysql.connection.cursor()
        cur.execute('INSERT INTO messages (message) VALUES (%s)', [new_message])
        mysql.connection.commit()
        cur.close()
        return jsonify({'message': new_message})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    try:
        with mysql.connection.cursor() as cur:
            cur.execute('SELECT 1')
        return jsonify({"status": "healthy", "db": "connected"}), 200
    except Exception:
        return jsonify({"status": "unhealthy", "db":"disconnected"}), 500

if __name__ == '__main__':
    # Initialize DB before starting the server
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
