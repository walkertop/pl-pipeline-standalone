#!/usr/bin/env bash
set -euo pipefail

cat > app/users.py <<'PY'
class UserStore:
    def __init__(self):
        self._users = {}
        self._next_id = 1

    def create_user(self, name, email):
        user = {
            "id": self._next_id,
            "name": name,
            "email": email,
            "active": True,
        }
        self._users[self._next_id] = user
        self._next_id += 1
        return user

    def get_user(self, user_id):
        return self._users.get(user_id)

    def update_user(self, user_id, **changes):
        user = self._users.get(user_id)
        if not user:
            return None
        user.update(changes)
        return user

    def delete_user(self, user_id):
        return False

    def list_users(self):
        return list(self._users.values())
PY
