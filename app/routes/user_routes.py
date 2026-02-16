from flask import Blueprint, request, jsonify

user_bp = Blueprint('users', __name__)

# Shared in-memory user store
users = [
    {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'},
    {'id': 2, 'name': 'Jane Smith', 'email': 'jane@example.com'}
]

@user_bp.route('/', methods=['GET'])
def get_users():
    return jsonify(users)

@user_bp.route('/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = next((u for u in users if u['id'] == user_id), None)
    if user:
        return jsonify(user)
    return jsonify({'error': 'User not found'}), 404

@user_bp.route('/', methods=['POST'])
def create_user():
    data = request.get_json()
    if not data or 'name' not in data or 'email' not in data:
        return jsonify({'error': 'Name and email are required'}), 400

    new_user = {
        'id': max(u['id'] for u in users) + 1 if users else 1,
        'name': data['name'],
        'email': data['email']
    }
    users.append(new_user)
    return jsonify(new_user), 201