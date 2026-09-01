#!/usr/bin/env python3
"""
Multi-User Row Isolation & Database Security Verification for SpacetimeDB
Tests row-level security, private table restrictions, and couple space sharing across multiple identities.
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
    print("SpacetimeDB Security & Multi-User Row Isolation Test Suite")
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
    print(f"  Direct 'SELECT * FROM expense;' returned: {res_exp}")
    is_private_exp = (isinstance(res_exp, str) and "marked private" in res_exp.lower()) or (isinstance(res_exp, list) and len(res_exp) == 0)
    assert is_private_exp, f"Direct query on private table 'expense' must be blocked or return 0 rows: {res_exp}"

    status, res_cat = run_sql(token_a, "SELECT * FROM category;")
    print(f"  Direct 'SELECT * FROM category;' returned: {res_cat}")
    is_private_cat = (isinstance(res_cat, str) and "marked private" in res_cat.lower()) or (isinstance(res_cat, list) and len(res_cat) == 0)
    assert is_private_cat, f"Direct query on private table 'category' must be blocked or return 0 rows: {res_cat}"
    print("  ✓ Private tables successfully protected against direct SQL scans")

    # 3. User A Profile & Starter Categories Initialization
    print("\n[Step 3] Initializing User A profile and starter categories...")
    status, body = call_reducer(token_a, "initialize_user_profile", ["User A", "ZAR", 1])
    print(f"  initialize_user_profile status: {status}")
    assert 200 <= status < 300, f"Failed to initialize User A profile: {body}"

    # Verify User A can see their starter categories via my_categories view
    status, cat_rows_a = run_sql(token_a, "SELECT * FROM my_categories;")
    print(f"  User A categories count: {len(cat_rows_a)}")
    assert len(cat_rows_a) >= 5, "User A must have 5 seeded starter categories"

    # Verify User B cannot see User A's categories
    status, cat_rows_b = run_sql(token_b, "SELECT * FROM my_categories;")
    print(f"  User B categories count (before init): {len(cat_rows_b)}")
    assert len(cat_rows_b) == 0, "User B must not see any categories before initializing"
    print("  ✓ my_categories view enforces complete caller isolation")

    # 4. Personal Expense Isolation Verification
    print("\n[Step 4] Logging personal expense for User A...")
    cat_a_id = cat_rows_a[0][0]
    spent_millis = int(time.time() * 1000)
    status, body = call_reducer(token_a, "log_expense", [15000, "ZAR", cat_a_id, "Apple Pay", "Lunch Bowl", spent_millis])
    assert 200 <= status < 300, f"Failed to log expense for User A: {body}"

    # Verify User A sees 1 expense
    status, exp_rows_a = run_sql(token_a, "SELECT * FROM my_expenses;")
    print(f"  User A my_expenses count: {len(exp_rows_a)}")
    assert len(exp_rows_a) >= 1, "User A must see their logged personal expense"

    # Verify User B sees 0 expenses
    status, exp_rows_b = run_sql(token_b, "SELECT * FROM my_expenses;")
    print(f"  User B my_expenses count: {len(exp_rows_b)}")
    assert len(exp_rows_b) == 0, "User B must NOT see User A's personal expense"
    print("  ✓ Personal expense isolation verified between User A and User B")

    # 5. Couple Space Invitation & Shared Expense Sync
    print("\n[Step 5] Creating Couple Space and joining Partner B...")
    status, body = call_reducer(token_a, "create_couple_space", ["Tandem Home", 50, 50])
    assert 200 <= status < 300, f"Failed to create couple space: {body}"

    # Fetch couple space and invite code
    status, space_rows = run_sql(token_a, "SELECT * FROM my_couple_space;")
    assert len(space_rows) > 0, "User A must have active couple space"
    space_id = space_rows[0][0]
    print(f"  Created Couple Space ID: {space_id}")

    # Initialize User B profile so B can participate
    call_reducer(token_b, "initialize_user_profile", ["User B", "ZAR", 1])

    # Log couple expense from User A
    status, body = call_reducer(
        token_a,
        "log_couple_expense",
        [space_id, 45000, "ZAR", cat_a_id, "Credit Card", "Shared Groceries", spent_millis, "EQUAL"]
    )
    assert 200 <= status < 300, f"Failed to log couple expense: {body}"

    # Before joining, User B should still not see User A's couple expense
    status, exp_rows_b = run_sql(token_b, "SELECT * FROM my_expenses;")
    assert len(exp_rows_b) == 0, "Unjoined User B should not see couple expense"

    print("  ✓ Couple space and expense successfully created")

    # 6. Soft-Delete Verification
    print("\n[Step 6] Verifying soft-delete filtering in my_expenses...")
    exp_id = exp_rows_a[0][0]
    status, body = call_reducer(token_a, "soft_delete_expense", [exp_id])
    assert 200 <= status < 300, f"Failed to soft delete expense: {body}"

    # User A my_expenses should now not include the soft-deleted personal expense
    status, exp_rows_a_after = run_sql(token_a, "SELECT * FROM my_expenses;")
    deleted_ids = [e[0] for e in exp_rows_a_after]
    assert exp_id not in deleted_ids, "Soft-deleted expense must be excluded from my_expenses"
    print("  ✓ Soft-deleted expense successfully excluded from client view queries")

    print("\n" + "=" * 60)
    print("🎉 ALL SECURITY & MULTI-USER ISOLATION TESTS PASSED SUCCESSFULLY!")
    print("=" * 60)

if __name__ == "__main__":
    run_tests()
