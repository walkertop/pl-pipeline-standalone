import unittest

from app.users import UserStore


class UserStoreTest(unittest.TestCase):
    def test_create_and_get_user(self):
        store = UserStore()

        user = store.create_user("Ada", "ada@example.com")

        self.assertEqual(user["id"], 1)
        self.assertEqual(user["name"], "Ada")
        self.assertTrue(user["active"])
        self.assertEqual(store.get_user(1)["email"], "ada@example.com")

    def test_update_user(self):
        store = UserStore()
        user = store.create_user("Ada", "ada@example.com")

        updated = store.update_user(user["id"], name="Ada Lovelace", active=False)

        self.assertEqual(updated["name"], "Ada Lovelace")
        self.assertFalse(updated["active"])
        self.assertEqual(store.get_user(user["id"])["name"], "Ada Lovelace")

    def test_delete_user(self):
        store = UserStore()
        user = store.create_user("Ada", "ada@example.com")

        self.assertTrue(store.delete_user(user["id"]))
        self.assertIsNone(store.get_user(user["id"]))
        self.assertFalse(store.delete_user(user["id"]))

    def test_list_users_returns_copies(self):
        store = UserStore()
        store.create_user("Ada", "ada@example.com")
        users = store.list_users()

        users[0]["name"] = "mutated"

        self.assertEqual(store.get_user(1)["name"], "Ada")


if __name__ == "__main__":
    unittest.main()
