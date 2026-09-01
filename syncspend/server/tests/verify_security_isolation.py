#!/usr/bin/env python3
"""
Multi-User Row Isolation & Database Security Verification for SpacetimeDB
Tests row-level security, private table restrictions, profile/category management,
envelope budgeting, soft-delete & restore, and couple space sharing across multiple identities.
"""

import sys
import json
import urllib.request
import urllib.error
import ssl
import time

HOST_URL = "https://maincloud.spacetimedb.com"
DB_NAME = "ad-guitar-1941"

ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

def http_post(url, headers, data):
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, context=ssl_context) as response:
            res_data = response.read()
            return response.status, res_data.decode("utf-8")
    except urllib.error.HTTPError as e:
        res_data = e.read()
        return e.code, res_data.decode("utf-8")
    except Exception as e:
        return 500, str(e)

def get_identity():
    status, body = http_post(f"{HOST_URL}/v1/identity", {}, b"")
    if status != 200:
        raise RuntimeError(f"Failed to generate identity: {status} {body}")
    data = json.loads(body)
    return data["token"], data["identity"]

def call_reducer(token, reducer_name, args):
    url = f"{HOST_URL}/v1/database/{DB_NAME}/call/{reducer_name}"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}"
    }
    payload = json.dumps(args).encode("utf-8")
    status, body = http_post(url, headers, payload)
    return status, body

def run_sql(token, query):
    url = f"{HOST_URL}/v1/database/{DB_NAME}/sql"
    headers = {
        "Content-Type": "text/plain",
        "Authorization": f"Bearer {token}"
    }
    status, body = http_post(url, headers, query.encode("utf-8"))
    if status == 200:
        try:
            parsed = json.loads(body)
            if parsed and len(parsed) > 0 and "rows" in parsed[0]:
                return status, parsed[0]["rows"]
            return status, []
        except Exception:
            return status, []
    return status, body

def run_tests():
    print("=" * 60)
    print("SpacetimeDB Security & Single-Player Engine Test Suite")
    print(f"Target Server: {HOST_URL} (Database: {DB_NAME})")
    print("=" * 60)

    # 1. Provision User A and User B identities
    print("\n[Step 1] Provisioning independent identities...")
    token_a, ident_a = get_identity()
    print(f"  User A Identity: {ident_a[:16]}...")
    token_b, ident_b = get_identity()
    print(f"  User B Identity: {ident_b[:16]}...")
    assert ident_a != ident_b, "Identities must be unique"
    print("  ✓ Identities successfully provisioned")

    # 2. Test Private Table Access Restriction
    print("\n[Step 2] Testing private table security restrictions...")
    status, res_exp = run_sql(token_a, "SELECT * FROM expense;")
    is_private_exp = (isinstance(res_exp, str) and "marked private" in res_exp.lower()) or (isinstance(res_exp, list) and len(res_exp) == 0)
    assert is_private_exp, f"Direct query on private table 'expense' must be blocked or return 0 rows: {res_exp}"

    status, res_cat = run_sql(token_a, "SELECT * FROM category;")
    is_private_cat = (isinstance(res_cat, str) and "marked private" in res_cat.lower()) or (isinstance(res_cat, list) and len(res_cat) == 0)
    assert is_private_cat, f"Direct query on private table 'category' must be blocked or return 0 rows: {res_cat}"
    print("  ✓ Private tables successfully protected against direct SQL scans")

    # 3. User Profile Initialization & Clamping
    print("\n[Step 3] Initializing User A profile with out-of-range payday anchor (day 31)...")
    status, body = call_reducer(token_a, "initialize_user_profile", ["User A", "ZAR", 31])
    assert 200 <= status < 300, f"Failed to initialize User A profile: {body}"

    status, profile_rows_a = run_sql(token_a, "SELECT * FROM my_profile;")
    assert len(profile_rows_a) == 1, "User A profile must exist"
    billing_cycle_day = profile_rows_a[0][3]
    print(f"  Profile payday day clamped to: {billing_cycle_day}")
    assert billing_cycle_day == 28, f"Day 31 must be clamped to 28, got {billing_cycle_day}"

    # Verify 5 starter categories seeded
    status, cat_rows_a = run_sql(token_a, "SELECT * FROM my_categories;")
    print(f"  User A starter categories count: {len(cat_rows_a)}")
    assert len(cat_rows_a) == 5, "User A must have 5 seeded starter categories"

    # Verify User B cannot see User A's profile or categories
    status, profile_rows_b = run_sql(token_b, "SELECT * FROM my_profile;")
    assert len(profile_rows_b) == 0, "User B must not see User A's profile"
    status, cat_rows_b = run_sql(token_b, "SELECT * FROM my_categories;")
    assert len(cat_rows_b) == 0, "User B must not see User A's categories"
    print("  ✓ User profile & starter categories verified with caller isolation")

    # 4. Profile Updating
    print("\n[Step 4] Updating User A profile (payday to 25th, name to 'Jordan')...")
    status, body = call_reducer(token_a, "update_user_profile", ["Jordan", 25])
    assert 200 <= status < 300, f"Failed to update User A profile: {body}"

    status, profile_rows_a = run_sql(token_a, "SELECT * FROM my_profile;")
    assert profile_rows_a[0][1] == "Jordan", f"Display name mismatch: {profile_rows_a[0][1]}"
    assert profile_rows_a[0][3] == 25, f"Billing cycle day mismatch: {profile_rows_a[0][3]}"
    print("  ✓ Profile update successfully applied")

    # 5. Custom Envelope Category Lifecycle (Create, Update, Archive)
    print("\n[Step 5] Testing Category Envelope lifecycle (Create, Update, Archive)...")
    status, body = call_reducer(
        token_a,
        "create_category",
        ["Tech Subscriptions", "laptopcomputer", "#6366F1", {"some": 50000}]
    )
    assert 200 <= status < 300, f"Failed to create category: {body}"

    status, cat_rows_a = run_sql(token_a, "SELECT * FROM my_categories;")
    assert len(cat_rows_a) == 6, f"Expected 6 categories, found {len(cat_rows_a)}"
    tech_cat = [c for c in cat_rows_a if c[2] == "Tech Subscriptions"][0]
    tech_cat_id = tech_cat[0]

    # Update category
    status, body = call_reducer(
        token_a,
        "update_category",
        [tech_cat_id, "Cloud & Tech", "cloud.fill", "#4F46E5", {"some": 75000}]
    )
    assert 200 <= status < 300, f"Failed to update category: {body}"

    status, cat_rows_a = run_sql(token_a, "SELECT * FROM my_categories;")
    updated_cat = [c for c in cat_rows_a if c[0] == tech_cat_id][0]
    assert updated_cat[2] == "Cloud & Tech", f"Category name not updated: {updated_cat[2]}"
    print("  ✓ Category updated successfully")

    # User B unauthorized attempt to update User A's category
    status, body = call_reducer(
        token_b,
        "update_category",
        [tech_cat_id, "Hacked Category", "exclamationmark.triangle", "#FF0000", {"none": []}]
    )
    assert status >= 400 or "Unauthorized" in body, "User B must not be able to update User A's category"
    print("  ✓ Cross-user category modification forbidden")

    # Archive category
    status, body = call_reducer(token_a, "archive_category", [tech_cat_id])
    assert 200 <= status < 300, f"Failed to archive category: {body}"

    status, cat_rows_a = run_sql(token_a, "SELECT * FROM my_categories;")
    archived_found = any(c[0] == tech_cat_id for c in cat_rows_a)
    assert not archived_found, "Archived category must be hidden from my_categories view"
    print("  ✓ Category archive successfully filtered out of active views")

    # 6. Expense CRUD, Soft-Delete & Restore Lifecycle
    print("\n[Step 6] Testing Expense CRUD, Soft-Delete & Restore...")
    groceries_cat_id = cat_rows_a[0][0]
    spent_millis = int(time.time() * 1000)
    status, body = call_reducer(
        token_a,
        "log_expense",
        [2499, "ZAR", groceries_cat_id, "Apple Pay", "Organic Milk", spent_millis]
    )
    assert 200 <= status < 300, f"Failed to log expense: {body}"

    status, exp_rows_a = run_sql(token_a, "SELECT * FROM my_expenses;")
    assert len(exp_rows_a) >= 1, "User A must see logged expense"
    exp_id = exp_rows_a[0][0]

    # Update expense
    status, body = call_reducer(
        token_a,
        "update_expense",
        [exp_id, 2999, "ZAR", groceries_cat_id, "Apple Pay", "Organic Oat Milk", spent_millis, "PERSONAL"]
    )
    assert 200 <= status < 300, f"Failed to update expense: {body}"

    # Soft delete expense
    status, body = call_reducer(token_a, "soft_delete_expense", [exp_id])
    assert 200 <= status < 300, f"Failed to soft delete expense: {body}"

    status, exp_rows_a = run_sql(token_a, "SELECT * FROM my_expenses;")
    assert not any(e[0] == exp_id for e in exp_rows_a), "Soft-deleted expense must be excluded from my_expenses"
    print("  ✓ Expense soft-deleted and excluded from active view")

    # Restore expense (5-second transient undo backend capability)
    status, body = call_reducer(token_a, "restore_expense", [exp_id])
    assert 200 <= status < 300, f"Failed to restore expense: {body}"

    status, exp_rows_a = run_sql(token_a, "SELECT * FROM my_expenses;")
    assert any(e[0] == exp_id for e in exp_rows_a), "Restored expense must reappear in my_expenses"
    print("  ✓ Expense restored and reappears in active view")

    # 7. Couple Space and Cross-User Isolation
    print("\n[Step 7] Verifying Couple Space and Cross-User Sharing Isolation...")
    status, body = call_reducer(token_a, "create_couple_space", ["Tandem Home", 60, 40])
    assert 200 <= status < 300, f"Failed to create couple space: {body}"

    status, space_rows = run_sql(token_a, "SELECT * FROM my_couple_space;")
    assert len(space_rows) > 0, "User A must have active couple space"
    space_id = space_rows[0][0]

    # User B initializes profile
    call_reducer(token_b, "initialize_user_profile", ["User B", "ZAR", 15])

    # User A logs couple expense
    status, body = call_reducer(
        token_a,
        "log_couple_expense",
        [space_id, 50000, "ZAR", groceries_cat_id, "Credit Card", "Weekly Dinner", spent_millis, "PROPORTIONAL"]
    )
    assert 200 <= status < 300, f"Failed to log couple expense: {body}"

    # User B should NOT see couple expense before joining
    status, exp_rows_b = run_sql(token_b, "SELECT * FROM my_expenses;")
    assert len(exp_rows_b) == 0, "Unjoined partner must not see couple expenses"

    print("\n" + "=" * 60)
    print("🎉 ALL SINGLE-PLAYER & BACKEND ENGINE TESTS PASSED SUCCESSFULLY!")
    print("=" * 60)

if __name__ == "__main__":
    run_tests()

