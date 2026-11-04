
import csv
import random
from pathlib import Path
from datetime import date, timedelta

random.seed(42)

DATA_DIR = Path("data")
DATA_DIR.mkdir(exist_ok=True)

NUM_CUSTOMERS = 1000
NUM_PRODUCTS = 150
NUM_ORDERS = 3000

cities = [
    "Mumbai", "Pune", "Delhi", "Bengaluru", "Hyderabad",
    "Chennai", "Nashik", "Nagpur", "Jaipur", "Kolkata",
    "Ahmedabad", "Indore"
]

first_names = [
    "Aarav", "Vivaan", "Aditya", "Arjun", "Rohan",
    "Rahul", "Karan", "Kabir", "Ishaan", "Dev",
    "Ananya", "Diya", "Aadhya", "Priya", "Sneha",
    "Kavya", "Riya", "Meera", "Ishita", "Aditi"
]

last_names = [
    "Sharma", "Patel", "Verma", "Joshi", "Singh",
    "Gupta", "Mehta", "Shah", "Reddy", "Nair",
    "Kulkarni", "Deshmukh", "Pawar", "Chopra", "Rao"
]

product_catalog = {
    "Electronics": [
        "Wireless Mouse", "Mechanical Keyboard", "Headphones",
        "Smart Watch", "Webcam", "Bluetooth Speaker"
    ],
    "Accessories": [
        "USB-C Cable", "Laptop Stand", "Phone Case",
        "Power Bank", "Screen Protector"
    ],
    "Home": [
        "Desk Lamp", "Water Bottle", "Storage Box",
        "Cushion", "Wall Clock"
    ],
    "Fashion": [
        "T-Shirt", "Backpack", "Wallet",
        "Sneakers", "Sunglasses"
    ],
    "Books": [
        "Python Programming Book", "SQL Guide",
        "Data Science Handbook", "Novel", "Notebook"
    ]
}


def write_csv(filename, rows, fields):
    with open(DATA_DIR / filename, "w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


# 1. CUSTOMERS
customers = []

for customer_id in range(1, NUM_CUSTOMERS + 1):
    customers.append({
        "customer_id": customer_id,
        "name": (
            f"{random.choice(first_names)} "
            f"{random.choice(last_names)}"
        ),
        "email": f"customer{customer_id}@example.com",
        "city": random.choice(cities),
        "signup_date": (
            date(2024, 1, 1)
            + timedelta(days=random.randint(0, 1000))
        ).isoformat()
    })

write_csv(
    "customers.csv",
    customers,
    ["customer_id", "name", "email", "city", "signup_date"]
)


# 2. PRODUCTS: EXACTLY 150
products = []
product_id = 1

catalog_items = [
    (category, name)
    for category, names in product_catalog.items()
    for name in names
]

while len(products) < NUM_PRODUCTS:
    category, name = catalog_items[(product_id - 1) % len(catalog_items)]

    products.append({
        "product_id": product_id,
        "product_name": f"{name} Model {product_id}",
        "category": category,
        "price": round(random.uniform(99, 25000), 2),
        "stock": random.randint(20, 200)
    })

    product_id += 1

write_csv(
    "products.csv",
    products,
    ["product_id", "product_name", "category", "price", "stock"]
)


# 3. ORDERS
orders = []
statuses = ["Delivered", "Pending", "Shipped", "Cancelled"]
status_weights = [60, 15, 15, 10]

for order_id in range(1, NUM_ORDERS + 1):
    orders.append({
        "order_id": order_id,
        "customer_id": random.randint(1, NUM_CUSTOMERS),
        "order_date": (
            date(2025, 1, 1)
            + timedelta(days=random.randint(0, 650))
        ).isoformat(),
        "order_status": random.choices(
            statuses, weights=status_weights, k=1
        )[0]
    })

write_csv(
    "orders.csv",
    orders,
    ["order_id", "customer_id", "order_date", "order_status"]
)


# 4. ORDER ITEMS WITH HISTORICAL UNIT PRICE


import csv
import os

data_folder = "data"

products_file = os.path.join(data_folder, "products.csv")
order_items_file = os.path.join(data_folder, "order_items.csv")

# Load product prices
with open(products_file, "r", newline="", encoding="utf-8") as file:
    products = list(csv.DictReader(file))

product_prices = {
    int(row["product_id"]): float(row["price"])
    for row in products
}

# Load existing order items
with open(order_items_file, "r", newline="", encoding="utf-8") as file:
    order_items = list(csv.DictReader(file))

# Find missing product IDs before changing the file
missing_ids = sorted({
    int(item["product_id"])
    for item in order_items
    if int(item["product_id"]) not in product_prices
})

if missing_ids:
    print("ERROR: These product IDs are missing from products.csv:")
    print(missing_ids)
    print("No changes were made to order_items.csv.")
else:
    columns = [
        "order_item_id",
        "order_id",
        "product_id",
        "quantity",
        "unit_price"
    ]

    for item in order_items:
        product_id = int(item["product_id"])
        item["unit_price"] = f"{product_prices[product_id]:.2f}"

    with open(order_items_file, "w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=columns)
        writer.writeheader()
        writer.writerows(order_items)

    print("SUCCESS! order_items.csv has been fixed.")
    print("Total order items:", len(order_items))


# 5. PAYMENTS
payments = []
payment_id = 1
payment_modes = ["UPI", "Card", "Net Banking", "Cash"]

for order in orders:
    # Generate a payment for delivered orders only.
    if order["order_status"] == "Delivered":
        payments.append({
            "payment_id": payment_id,
            "order_id": order["order_id"],
            "payment_mode": random.choice(payment_modes),
            "amount": f"{order_totals[order['order_id']]:.2f}",
            "payment_date": order["order_date"]
        })
        payment_id += 1

write_csv(
    "payments.csv",
    payments,
    ["payment_id", "order_id", "payment_mode", "amount", "payment_date"]
)


# 6. DATA SUMMARY
print("\nDATA GENERATION COMPLETED!")
print("-" * 40)
print(f"Customers:   {len(customers):,}")
print(f"Products:    {len(products):,}")
print(f"Orders:      {len(orders):,}")
print(f"Order items: {len(order_items):,}")
print(f"Payments:    {len(payments):,}")
print(f"\nCSV files saved in: {DATA_DIR.resolve()}")


import os
print("CSV FILE LOCATION:", os.path.abspath("data/order_items.csv"))