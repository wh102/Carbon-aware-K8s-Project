from flask import Flask, render_template, request, jsonify
from flask_mysqldb import MySQL
from prometheus_client import Gauge
from prometheus_client import make_wsgi_app
from werkzeug.middleware.dispatcher import DispatcherMiddleware
import os
import time
import requests
import signal
import sys
import socket
import logging
import threading
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# 1. Database Configuration
app.config['MYSQL_HOST'] = os.environ.get('MYSQL_HOST', 'mysql')
app.config['MYSQL_USER'] = os.environ.get('MYSQL_USER', 'root')
app.config['MYSQL_PASSWORD'] = os.environ.get('MYSQL_PASSWORD', 'admin')
app.config['MYSQL_DB'] = os.environ.get('MYSQL_DB', 'testdb')


mysql = MySQL(app)

carbon_intensity_gauge = Gauge('carbon_intensity', 'UK carbon intensity')

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
            logger.info("Successfully connected...")
            return True
        except Exception as e:
            logger.warning(f"Waiting for MySQL... (Attempt {i+1}/10). Error: {e}")
            time.sleep(5)
    return False

def init_db_background():
    while not init_db():
        time.sleep(5)

    
last_intensity = 0
last_fetch_time = 0
CACHE_DURATION = 60  

def get_cached_carbon_intensity():
    global last_intensity, last_fetch_time
    
    now = time.time()
    
    if now - last_fetch_time > CACHE_DURATION:
        try:
            url = "https://api.carbonintensity.org.uk/intensity"
            response = requests.get(url, timeout=5)
            
            if response.status_code == 200:
                data = response.json()
                value = data['data'][0]['intensity']['actual']
                last_intensity = value
                carbon_intensity_gauge.set(value)
                last_fetch_time = now
        except Exception as e:
            logger.error(f"Carbon API error: {e}")
    
    return last_intensity

def update_carbon_loop():
    while True:
        get_cached_carbon_intensity()
        time.sleep(60)


app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
    '/metrics': make_wsgi_app()
})

def handle_sigterm(sig, frame):
    logger.info("Received SIGTERM, shutting down gracefully...")
    try:
        mysql.connection.close()
        logger.info("MySQL connections closed.")
    except Exception as e:
        logger.error(f"Error during cleanup: {e}")      
    sys.exit(0)

signal.signal(signal.SIGTERM, handle_sigterm)

@app.route('/')
def hello():
    pod_name = socket.gethostname()
    intensity = get_cached_carbon_intensity() 
    
    try:
        with mysql.connection.cursor() as cur:
            cur.execute('SELECT message FROM messages')
            messages = cur.fetchall()
        
        return render_template('index.html', messages=messages, intensity=intensity, pod_name=pod_name)
    except Exception as e:
        return render_template('index.html', messages=[], intensity=intensity, pod_name=pod_name, error=str(e))


@app.route('/submit', methods=['POST'])
def submit():
    msg = request.form.get('new_message') or (request.json and request.json.get('new_message'))
    try:
        cur = mysql.connection.cursor()
        cur.execute('INSERT INTO messages (message) VALUES (%s)', [msg])
        mysql.connection.commit()
        cur.close()
        return jsonify({'message': msg})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    return "OK", 200

def check_db_connection(retries=5, delay=2):
    for i in range(retries):
        try:
            with mysql.connection.cursor() as cur:
                cur.execute('SELECT 1')
            return True
        except Exception as e:
            logger.warning(f"DB connection failed (attempt {i+1}): {e}")
            time.sleep(delay)
    return False

@app.route('/ready')
def ready():
    if check_db_connection():
        return jsonify({"status": "ready"}), 200
    return jsonify({"status": "not ready"}), 500

def start_background_threads():
    if not hasattr(app, "threads_started"):
        threading.Thread(target=init_db_background, daemon=True).start()
        threading.Thread(target=update_carbon_loop, daemon=True).start()
        app.threads_started = True

start_background_threads()
