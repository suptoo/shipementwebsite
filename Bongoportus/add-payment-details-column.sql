-- Add payment_details column to orders table for storing bKash/Nagad/Card payment info
-- Run this in Supabase SQL Editor if the column doesn't exist

-- Add payment_details column (JSONB for flexible payment data)
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_details JSONB;

-- Example payment_details structure:
-- For bKash/Nagad/Upay:
-- {
--   "method": "bkash",
--   "transactionId": "TXN123ABC",
--   "accountNumber": "01712345678",
--   "timestamp": "2026-01-01T15:00:00Z"
-- }
--
-- For Card (Visa/Mastercard):
-- {
--   "method": "visa",
--   "transactionId": "TXN456DEF",
--   "cardType": "visa",
--   "timestamp": "2026-01-01T15:00:00Z"
-- }

-- Verify the column was added
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'orders' AND column_name = 'payment_details';
