# Naa Luxe

A premium Ghanaian luxury-commerce storefront built with Next.js, TypeScript and Supabase. It includes a responsive storefront, Supabase email/password authentication, a database-backed catalog/community, admin-protected product/order endpoints, and server-side Paystack transaction verification.

## Run locally

1. Install Node.js 20+ and run `npm install`.
2. Create a Supabase project. In its SQL Editor, run `supabase/schema.sql` (it creates tables, RLS policies, the first-user admin trigger, and the public media bucket).
3. Copy `.env.example` to `.env.local` and set your Supabase URL, anon key, service-role key, Paystack secret key and public site URL. Never put the service-role or Paystack secret in a `NEXT_PUBLIC_*` variable.
4. Configure Supabase Auth email/password and your site redirect URLs. Set the project email provider and production SMTP before launch.
5. Create a Paystack account and use its test secret key for sandbox testing. Register the callback URL `${NEXT_PUBLIC_SITE_URL}/api/payments/verify` in Paystack.
6. Run `npm run dev`, then `npm run build` before deployment.

The first profile created after installing the schema is assigned `admin` under a transaction-scoped PostgreSQL advisory lock; later signups receive `customer`. If test users already exist, remove them before testing the first-signup behavior. Do not delete the first admin profile without intentionally transferring admin access.

## Implemented

- Luxury responsive landing, catalog search/category filtering, product detail, local cart and wishlist, account order history, checkout delivery fields (including GhanaPost GPS), and newsletter sign-up.
- Supabase-backed customer registration/login. User roles are assigned by the database trigger, with RLS and a role-protection trigger.
- Admin overview and order status update API; product creation API with published/stock/price fields.
- Paystack GHS payment initialization using server-calculated product prices, plus server-side verification of successful status, currency and exact amount before setting the order paid.
- Community post feed, member text posts and likes; schema includes comments/replies, reports, announcements, profile images, notifications and product media storage policies.

## Important production setup / current limitations

This repository is a working starter implementation, not a fully audited or finished production commerce system. Before accepting real orders, test end-to-end in a private staging project, configure email verification/password recovery, TLS and rate limits, privacy/retention policies, monitoring, backups and production SMTP. Product images are currently entered as URLs in the admin form; the storage bucket and policies are provisioned but a file-upload interface is not yet included. Community image uploads, comment/reply/report moderation UI, customer-management UI, address book, interactive sales charts and password-reset screens are not yet implemented. Stock is checked at checkout but not decremented/reserved, and delivery pricing, tax, shipping workflows, refunds and webhook reconciliation need business-specific implementation. Payment callback verification is server-side; add Paystack webhook signature validation and idempotent reconciliation before production. Review the schema's public community/profile visibility and all RLS policies for your privacy requirements.

The project cannot be integration-tested without Supabase and Paystack credentials. Use Paystack test mode and verify first-admin creation, customer isolation and payment/order edge cases before go-live.
