# MyCosmetics API Documentation

## Base URL
- Production:  `https://api.mycosmetics.app`
- Staging:     `https://staging-api.mycosmetics.app`
- Development: `http://localhost:8080`

## Authentication
All protected endpoints require:
```
Authorization: Bearer <token>
```
Token obtained from `POST /auth/login`. Expires after 7 days (sliding).

## Endpoints

### Auth

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/register` | No | Create account |
| POST | `/auth/login` | No | Login, returns token |
| POST | `/auth/logout` | Yes | Revoke current token |
| POST | `/auth/forgotPassword` | No | Request reset email |
| POST | `/auth/resetPassword` | No | Reset with email token |
| POST | `/auth/changePassword` | Yes | Change password |

**Login Request:**
```json
{ "email": "user@example.com", "password": "secure123" }
```
**Login Response:**
```json
{
  "token": "550e8400-e29b-41d4-a716-446655440000",
  "user": { "id": 1, "email": "user@example.com", "fullName": "Jane", "role": "customer" }
}
```

---

### Profile

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/profile/getProfile` | Yes | Get current user |
| POST | `/profile/updateProfile` | Yes | Update name/phone |
| POST | `/profile/listAddresses` | Yes | List addresses |
| POST | `/profile/addAddress` | Yes | Add address |
| POST | `/profile/deleteAddress` | Yes | Delete address |

---

### Catalog

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/product/search` | No | Search & filter products |
| POST | `/product/getDetails` | No | Get product with variants |
| POST | `/category/listTopLevel` | No | All top-level categories |
| POST | `/brand/listAll` | No | All brands |

**Product Search Request:**
```json
{
  "searchQuery": "lipstick",
  "categoryId": 3,
  "minPrice": 5.0,
  "maxPrice": 50.0,
  "sortBy": "ratingAvg",
  "page": 0,
  "pageSize": 20
}
```

---

### Cart & Orders

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/cart/getCart` | Yes | Current cart |
| POST | `/cart/addItem` | Yes | Add variant to cart |
| POST | `/cart/updateQuantity` | Yes | Change qty |
| POST | `/cart/removeItem` | Yes | Remove item |
| POST | `/coupon/apply` | Yes | Apply coupon code |
| POST | `/order/checkout` | Yes | Place order |
| POST | `/order/listMyOrders` | Yes | Order history |
| POST | `/order/getDetails` | Yes | Order detail |
| POST | `/order/cancel` | Yes | Cancel order |

**Checkout Request:**
```json
{ "addressId": 5 }
```
**Checkout Response:**
```json
{
  "order": { "id": 42, "total": 87.50, "status": "pending" },
  "items": [...]
}
```

---

### Payments

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/payment/initiate` | Yes | Create payment intent |
| POST | `/payment/getForOrder` | Yes | Get payment status |
| POST | `/payment/requestRefund` | Yes | Submit refund request |
| POST | `/webhooks/stripe` | None | Stripe webhook (signed) |

**Initiate Payment Request:**
```json
{
  "orderId": 42,
  "provider": "stripe",
  "method": "card",
  "idempotencyKey": "uuid-v4-from-client"
}
```
**Initiate Payment Response (Stripe):**
```json
{
  "paymentId": 7,
  "provider": "stripe",
  "clientSecret": "pi_xxx_secret_xxx",
  "amount": 87.50,
  "currency": "USD"
}
```

---

### BeautyTech

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/beautyTech/saveSkinAnalysis` | Yes | Save scan result + upsert profile |
| POST | `/beautyTech/getSkinProfile` | Yes | Get skin profile |
| POST | `/beautyTech/generateRecommendations` | Yes | Run 5-factor engine |
| POST | `/beautyTech/listRecommendationHistory` | Yes | Past sessions |
| POST | `/beautyTech/recordRecommendationEvent` | Yes | Track viewed/tried/bought |
| POST | `/beautyTech/listSavedLooks` | Yes | My saved looks |
| POST | `/beautyTech/saveLook` | Yes | Save a look |
| POST | `/beautyTech/recordTryOn` | Yes | Analytics event |

---

### Admin (requires admin/staff role)

| Method | Path | Permission | Description |
|---|---|---|---|
| POST | `/admin/getDashboardOverview` | reports:read | KPI summary |
| POST | `/admin/getDashboardCharts` | reports:read | Chart data |
| POST | `/admin/listProducts` | products:read | Product table |
| POST | `/admin/listOrders` | orders:read | Order table |
| POST | `/admin/listCustomers` | customers:read | Customer table |
| POST | `/admin/adjustStock` | inventory:write | Stock adjustment |
| POST | `/admin/suspendUser` | customers:write | Suspend account |
| POST | `/admin/getBeautyTechAnalytics` | analytics:read | AI metrics |
| POST | `/admin/listAuditLogs` | audit:read | Audit trail |

## Error Response Format
```json
{
  "error": true,
  "message": "Human-readable error description",
  "statusCode": 401
}
```

## Rate Limits
| Endpoint Group | Limit |
|---|---|
| Auth endpoints | 10 requests/minute per IP |
| General API | 60 requests/minute per IP |
| Upload | 5 requests/minute per IP |
| Webhook | Unlimited (signature verified) |

HTTP 429 returned when limit exceeded. Retry-After header included.
