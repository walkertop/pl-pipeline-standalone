#!/usr/bin/env bash
set -euo pipefail

test "${PL_FAILURE_KIND:-}" = "test_failure"
test -f "${PL_REPAIR_CONTEXT:-}"
grep -q "failure_kind: \`test_failure\`" "$PL_REPAIR_CONTEXT"
grep -q "Gate output" "$PL_REPAIR_CONTEXT"

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
        return dict(user)

    def get_user(self, user_id):
        user = self._users.get(user_id)
        return dict(user) if user else None

    def update_user(self, user_id, **changes):
        user = self._users.get(user_id)
        if not user:
            return None
        for key in ("name", "email", "active"):
            if key in changes:
                user[key] = changes[key]
        return dict(user)

    def delete_user(self, user_id):
        return self._users.pop(user_id, None) is not None

    def list_users(self):
        return [dict(user) for user in self._users.values()]
PY
