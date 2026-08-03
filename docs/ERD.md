# Entity-Relationship Diagram

## Bronze layer (`raw` schema)

```mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : places
    ORDERS ||--o{ ORDER_ITEMS : contains
    PRODUCTS ||--o{ ORDER_ITEMS : "sold in"

    CUSTOMERS {
        int customer_id PK
        varchar first_name
        varchar last_name
        varchar email UK
        varchar country
        varchar city
        date signup_date
        varchar customer_segment
    }

    PRODUCTS {
        int product_id PK
        varchar product_name
        varchar category
        varchar sub_category
        numeric unit_price
        numeric unit_cost
    }

    ORDERS {
        int order_id PK
        int customer_id FK
        date order_date
        varchar order_status
        varchar payment_method
        numeric shipping_cost
    }

    ORDER_ITEMS {
        int order_item_id PK
        int order_id FK
        int product_id FK
        int quantity
        numeric unit_price
        numeric discount_pct
    }

    DATE_DIM {
        date date_key PK
        int year
        int quarter
        int month
        int day_of_week
        bool is_weekend
    }
```

## Gold layer (`analytics` schema, built by dbt)

| Table | Grain | Description |
|---|---|---|
| `dim_customers` | 1 row / customer | Customer attributes + lifetime order stats |
| `dim_products` | 1 row / product | Product attributes + sales stats |
| `fct_orders` | 1 row / order | Order header + derived revenue/total |
| `customer_rfm` | 1 row / customer | RFM scores + segment label |
| `customer_clv` | 1 row / customer | Historical + predicted annual CLV |

`fct_orders.customer_id` references `dim_customers.customer_id`; `dim_products` joins to `fct_orders` via `raw.order_items` in the underlying staging models.
