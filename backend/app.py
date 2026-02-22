import smtplib
import random
import string
import time
import os
from datetime import datetime,timedelta,timezone
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from pymongo import MongoClient
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from bson.objectid import ObjectId

# +++++++++++++++++++++++
# EMAIL CONFIGURATION
# +++++++++++++++++++++++

SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SENDER_EMAIL = "bitverse.in@gmail.com"
SENDER_PASSWORD = "weij tfho wxrl cocr"

# ++++++++++++++++++++++++++
# OTP STORAGE (In-Memory)
# +++++++++++++++++++++++++++
# Format: { "email@domain.com": { "otp": "123456", "timestamp": 17000000.0 } }
otp_storage = {}
OTP_EXPIRY_SECONDS = 300  # 5 minutes


# ++++++++++++++++++++++++++
# FLASK APP INITIALIZATION
# ++++++++++++++++++++++++++
app = Flask(__name__)
CORS(app)

# ++++++++++++++++++++++++++
# UPLOADS CONFIG
# ++++++++++++++++++++++++++
UPLOAD_ROOT = os.path.join(os.path.dirname(__file__), 'uploads')
PROFILE_IMAGE_DIR = os.path.join(UPLOAD_ROOT, 'profile_images')
os.makedirs(PROFILE_IMAGE_DIR, exist_ok=True)

ALLOWED_IMAGE_EXTENSIONS = {"png", "jpg", "jpeg", "webp"}

def _allowed_image(filename: str) -> bool:
    if not filename or '.' not in filename:
        return False
    ext = filename.rsplit('.', 1)[1].lower()
    return ext in ALLOWED_IMAGE_EXTENSIONS

# ++++++++++++++++++++
# DATABASE SETUP
# ++++++++++++++++++++
CONNECTION_STRING = "mongodb+srv://someshkumarsahoo28_db_user:6wspRNRG0uTEFQEJ@cropdata.5tnllzt.mongodb.net/"
try:
    client = MongoClient(CONNECTION_STRING)
    db = client.get_database('cropintel_db')
    
    # Collections
    users_collection = db.get_collection('users')  # users
    chat_sessions_collection = db.get_collection('chat_sessions')  # chat history
    
    # Create indexes for performance
    users_collection.create_index("user_id", unique=True)
    users_collection.create_index("email", unique=True)
    chat_sessions_collection.create_index([("user_id", 1), ("session_id", 1)], unique=True)
    
    print("✅ Connected to MongoDB Atlas successfully!")
except Exception as e:
    print(f"❌ ERROR: Could not connect to MongoDB. {e}")
    client = None

# ++++++++++++++++++++++
# HELPER FUNCTIONS
# ++++++++++++++++++++++

def find_user_by_identifier(identifier):
    """
    Finds a user by username (user_id) or email.
    Returns: (user_document, user_type) or (None, None)
    """
    # If the identifier looks like an email, search by email first
    if '@' in identifier:
        user = users_collection.find_one({"email": identifier})
    else:
        user = users_collection.find_one({"user_id": identifier})
    if user:
        return user, "user"
    return None, None

def send_email_otp(recipient_email, otp):
    """Sends OTP via email."""
    try:
        subject = "CropIntel Verification Code"
        body = f"""Hello,

Your OTP for CropIntel login is: {otp}

This code expires in 5 minutes.

If you didn't request this code, please ignore this email.

Thank you,
BitVerse Team
"""

        msg = MIMEMultipart()
        msg['From'] = SENDER_EMAIL
        msg['To'] = recipient_email
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain'))

        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(SENDER_EMAIL, SENDER_PASSWORD)
        text = msg.as_string()
        server.sendmail(SENDER_EMAIL, recipient_email, text)
        server.quit()
        
        print(f"📧 OTP sent to {recipient_email}")
        return True
    except Exception as e:
        print(f"❌ Email Error: {e}")
        return False
    

def validate_otp(email, user_provided_otp):
    """
    Validates OTP for a given email.
    Returns: (success: bool, error_message: str or None)
    """
    record = otp_storage.get(email)
    
    if not record:
        return False, "OTP not found.Try again."
    
    if time.time() - record['timestamp'] > OTP_EXPIRY_SECONDS:
        return False, "OTP expired.Try again."
    
    if record['otp'] != user_provided_otp:
        return False, "Invalid OTP."
    
    return True, None

# ++++++++++++++++++++++++++++
# AUTHENTICATION ENDPOINTS
# ++++++++++++++++++++++++++++

@app.route('/send-otp', methods=['POST'])
def send_otp():
    """Sends OTP to email for verification."""
    data = request.json
    email = data.get('email')

    if not email:
        return jsonify({"status": "error", "message": "Email is required"}), 400

    # Check if email already exists in either collection
    if users_collection.find_one({"email": email}):
        return jsonify({"status": "error", "message": "Email already registered"}), 409

    # Generate 6-digit OTP
    otp = ''.join(random.choices(string.digits, k=6))
    
    # Store OTP with timestamp
    otp_storage[email] = {
        "otp": otp,
        "timestamp": time.time()
    }

    print(f"Generated OTP for {email}: {otp}")  # Remove in production

    if send_email_otp(email, otp):
        return jsonify({"status": "success", "message": "OTP sent to email"}), 200
    else:
        return jsonify({"status": "error", "message": "Failed to send email"}), 500
    

@app.route('/register', methods=['POST'])
def register_user():
    """Registers a new user."""
    data = request.json
    
    # Extract fields
    name = data.get('name')
    user_id = data.get('user_id')
    email = data.get('email')
    password = data.get('password')
    user_provided_otp = data.get('otp')

    # 1. Validate required fields
    required_fields = [name, user_id, email, password, user_provided_otp]
    if not all(required_fields):
        return jsonify({"status": "error", "message": "Missing required fields"}), 400


    # 2. Validate OTP
    otp_valid, otp_error = validate_otp(email, user_provided_otp)
    if not otp_valid:
        return jsonify({"status": "error", "message": otp_error}), 400

    # 3. Check for existing users
    if users_collection.find_one({"user_id": user_id}):
        return jsonify({"status": "error", "message": "User ID already exists"}), 409
    
    
    if users_collection.find_one({"email": email}):
        return jsonify({"status": "error", "message": "Email already exists"}), 409

    # 4. Hash password
    hashed_password = generate_password_hash(password)

    try:
        new_user = {
                "name": name,
                "user_id": user_id,
                "email": email,
                "password_hash": hashed_password,
                "created_at": datetime.now(timezone.utc)
            }
        users_collection.insert_one(new_user)
        print(f"✅ Registered new user: {user_id}")

        # Cleanup OTP after successful registration
        del otp_storage[email]
        
        return jsonify({
            "status": "success",
            "message": f"User registered successfully!"
        }), 201
    
    except Exception as e:
        print(f"❌ Registration Error: {e}")
        return jsonify({"status": "error", "message": "Registration failed"}), 500


@app.route('/personalization', methods=['POST'])
def save_personalization():
    """Saves personalization details for a user (identified by email or user_id)."""
    data = request.json or {}

    email = data.get('email')
    user_id = data.get('user_id')

    gender = data.get('gender')
    age_raw = data.get('age')
    crop_type = data.get('crop_type')
    region = data.get('region')
    soil_type = data.get('soil_type')

    if not email and not user_id:
        return jsonify({"status": "error", "message": "Email or user_id is required"}), 400

    if not gender:
        return jsonify({"status": "error", "message": "Gender is required"}), 400

    if age_raw is None or age_raw == "":
        return jsonify({"status": "error", "message": "Age is required"}), 400

    try:
        age_value = int(age_raw)
        if age_value <= 0 or age_value > 120:
            return jsonify({"status": "error", "message": "Invalid age"}), 400
    except Exception:
        return jsonify({"status": "error", "message": "Invalid age"}), 400

    query = {"email": email} if email else {"user_id": user_id}
    user = users_collection.find_one(query)
    if not user:
        return jsonify({"status": "error", "message": "User not found"}), 404

    personalization = {
        "age": age_value,
        "gender": gender,
        "crop_type": crop_type,
        "region": region,
        "soil_type": soil_type,
        "updated_at": datetime.now(timezone.utc),
    }

    users_collection.update_one(
        query,
        {"$set": {"personalization": personalization, "updated_at": datetime.now(timezone.utc)}},
    )

    return jsonify({
        "status": "success",
        "message": "Personalization saved",
    }), 200


@app.route('/personalization', methods=['GET'])
def get_personalization():
    """Fetch personalization details for a user (identified by email or user_id)."""
    email = request.args.get('email')
    user_id = request.args.get('user_id')

    if not email and not user_id:
        return jsonify({"status": "error", "message": "Email or user_id is required"}), 400

    query = {"email": email} if email else {"user_id": user_id}
    user = users_collection.find_one(query)
    if not user:
        return jsonify({"status": "error", "message": "User not found"}), 404

    personalization = user.get('personalization')
    if not personalization:
        return jsonify({"status": "error", "message": "Personalization not found"}), 404

    # Ensure JSON serializable response
    safe = {
        "age": personalization.get("age"),
        "gender": personalization.get("gender"),
        "crop_type": personalization.get("crop_type"),
        "region": personalization.get("region"),
        "soil_type": personalization.get("soil_type"),
    }

    return jsonify({
        "status": "success",
        "message": "Personalization fetched",
        "data": safe,
    }), 200


@app.route('/profile/update', methods=['POST'])
def update_profile():
    """Update basic profile fields (currently: name) for a user."""
    data = request.json or {}
    email = data.get('email')
    user_id = data.get('user_id')
    name = data.get('name')

    if not email and not user_id:
        return jsonify({"status": "error", "message": "Email or user_id is required"}), 400
    if not name or not str(name).strip():
        return jsonify({"status": "error", "message": "Name is required"}), 400

    query = {"email": email} if email else {"user_id": user_id}
    user = users_collection.find_one(query)
    if not user:
        return jsonify({"status": "error", "message": "User not found"}), 404

    users_collection.update_one(
        query,
        {"$set": {"name": str(name).strip(), "updated_at": datetime.now(timezone.utc)}},
    )

    return jsonify({
        "status": "success",
        "message": "Profile updated",
        "data": {"name": str(name).strip()},
    }), 200


@app.route('/profile/upload-image', methods=['POST'])
def upload_profile_image():
    """Upload and store a user's profile image."""
    email = request.form.get('email')
    user_id = request.form.get('user_id')

    if not email and not user_id:
        return jsonify({"status": "error", "message": "Email or user_id is required"}), 400

    file = request.files.get('image')
    if not file:
        return jsonify({"status": "error", "message": "Image file is required"}), 400

    filename = secure_filename(file.filename or '')
    if not _allowed_image(filename):
        return jsonify({"status": "error", "message": "Unsupported image type"}), 400

    query = {"email": email} if email else {"user_id": user_id}
    user = users_collection.find_one(query)
    if not user:
        return jsonify({"status": "error", "message": "User not found"}), 404

    ext = filename.rsplit('.', 1)[1].lower()
    safe_user_id = (user.get('user_id') or 'user').replace(' ', '_')
    ts = int(time.time())
    stored_name = f"{safe_user_id}_{ts}.{ext}"
    stored_path = os.path.join(PROFILE_IMAGE_DIR, stored_name)

    try:
        file.save(stored_path)
    except Exception as e:
        print(f"❌ Upload Error: {e}")
        return jsonify({"status": "error", "message": "Failed to save image"}), 500

    image_url = f"/uploads/profile_images/{stored_name}"

    users_collection.update_one(
        query,
        {"$set": {
            "profile_image": {
                "filename": stored_name,
                "url": image_url,
                "updated_at": datetime.now(timezone.utc),
            },
            "updated_at": datetime.now(timezone.utc)
        }},
    )

    return jsonify({
        "status": "success",
        "message": "Profile image uploaded",
        "data": {"url": image_url, "filename": stored_name},
    }), 200


@app.route('/uploads/profile_images/<path:filename>', methods=['GET'])
def serve_profile_image(filename):
    return send_from_directory(PROFILE_IMAGE_DIR, filename)


@app.route('/login', methods=['POST'])
def login_user():
    """Login endpoint – accepts username or email."""
    data = request.json
    identifier = data.get('identifier')  # can be username or email
    password = data.get('password')

    if not identifier or not password:
        return jsonify({"status": "error", "message": "Missing credentials"}), 400

    # Find user by username or email
    user, user_type = find_user_by_identifier(identifier)

    if not user:
        return jsonify({"status": "error", "message": "Invalid credentials"}), 401

    # Verify password
    if not check_password_hash(user['password_hash'], password):
        return jsonify({"status": "error", "message": "Invalid credentials"}), 401

    # Successful login
    return jsonify({
        "status": "success",
        "user": {
            "name": user['name'],
            "user_id": user.get('user_id'),
            "email": user['email']
        }
    }), 200


# ++++++++++++++++++++++++++++++++++
# PASSWORD RESET ENDPOINTS
# ++++++++++++++++++++++++++++++++++

@app.route('/reset-password/send-otp', methods=['POST'])
def reset_send_otp():
    """Sends OTP to email for password reset (email must be registered)."""
    data = request.json
    email = data.get('email')

    if not email:
        return jsonify({"status": "error", "message": "Email is required"}), 400

    # Email must exist
    if not users_collection.find_one({"email": email}):
        return jsonify({"status": "error", "message": "No account found with this email"}), 404

    otp = ''.join(random.choices(string.digits, k=6))
    otp_storage[email] = {"otp": otp, "timestamp": time.time()}
    print(f"Generated reset OTP for {email}: {otp}")

    if send_email_otp(email, otp):
        return jsonify({"status": "success", "message": "OTP sent to email"}), 200
    else:
        return jsonify({"status": "error", "message": "Failed to send email"}), 500


@app.route('/reset-password/verify-otp', methods=['POST'])
def reset_verify_otp():
    """Verifies OTP for password reset without changing the password."""
    data = request.json
    email = data.get('email')
    user_provided_otp = data.get('otp')

    if not email or not user_provided_otp:
        return jsonify({"status": "error", "message": "Email and OTP are required"}), 400

    otp_valid, otp_error = validate_otp(email, user_provided_otp)
    if not otp_valid:
        return jsonify({"status": "error", "message": otp_error}), 400

    return jsonify({"status": "success", "message": "OTP verified"}), 200


@app.route('/reset-password/reset', methods=['POST'])
def reset_password():
    """Resets password after OTP has been verified."""
    data = request.json
    email = data.get('email')
    new_password = data.get('new_password')

    if not email or not new_password:
        return jsonify({"status": "error", "message": "Email and new password are required"}), 400

    user = users_collection.find_one({"email": email})
    if not user:
        return jsonify({"status": "error", "message": "User not found"}), 404

    hashed = generate_password_hash(new_password)
    users_collection.update_one({"email": email}, {"$set": {"password_hash": hashed}})

    # Clear OTP after successful reset
    otp_storage.pop(email, None)

    print(f"✅ Password reset for: {email}")
    return jsonify({"status": "success", "message": "Password updated successfully"}), 200


# ++++++++++++++++++++++++++++++
# CHAT HISTORY ENDPOINTS
# ++++++++++++++++++++++++++++++

@app.route('/chat/sessions/save', methods=['POST'])
def save_chat_session():
    """Upserts a single chat session (creates or fully replaces)."""
    data = request.json or {}
    user_id = data.get('user_id')
    session = data.get('session')

    if not user_id:
        return jsonify({"status": "error", "message": "user_id is required"}), 400
    if not session or not session.get('session_id'):
        return jsonify({"status": "error", "message": "session with session_id is required"}), 400

    chat_sessions_collection.update_one(
        {"user_id": user_id, "session_id": session['session_id']},
        {"$set": {
            "user_id": user_id,
            "session_id": session['session_id'],
            "title": session.get('title', 'Chat'),
            "messages": session.get('messages', []),
            "updated_at": datetime.now(timezone.utc),
        }, "$setOnInsert": {
            "created_at": datetime.now(timezone.utc),
        }},
        upsert=True,
    )

    return jsonify({"status": "success", "message": "Session saved"}), 200


@app.route('/chat/sessions', methods=['GET'])
def get_chat_sessions():
    """Returns all chat sessions for a user, ordered newest first."""
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({"status": "error", "message": "user_id is required"}), 400

    sessions = list(
        chat_sessions_collection
        .find({"user_id": user_id}, {"_id": 0})
        .sort("updated_at", -1)
    )

    # Convert datetime objects to ISO strings for JSON
    for s in sessions:
        for key in ('created_at', 'updated_at'):
            if key in s and hasattr(s[key], 'isoformat'):
                s[key] = s[key].isoformat()

    return jsonify({"status": "success", "sessions": sessions}), 200


@app.route('/chat/sessions/<session_id>', methods=['DELETE'])
def delete_chat_session(session_id):
    """Deletes a single chat session."""
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({"status": "error", "message": "user_id is required"}), 400

    result = chat_sessions_collection.delete_one(
        {"user_id": user_id, "session_id": session_id}
    )
    if result.deleted_count == 0:
        return jsonify({"status": "error", "message": "Session not found"}), 404

    return jsonify({"status": "success", "message": "Session deleted"}), 200


# +++++++++++++++
# MAIN
# +++++++++++++++

if __name__ == '__main__':

    print(" Bit Verse - BACKEND")

    print(f"📡 Server running on http://23.0.0.201:5000 (binding to 0.0.0.0)")
    
    app.run(host='0.0.0.0', port=5000, debug=True)