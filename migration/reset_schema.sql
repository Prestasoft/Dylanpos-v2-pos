-- =====================================================
-- RESET SCHEMA - USAR CON CUIDADO
-- Elimina todas las tablas y las recrea
-- =====================================================

-- Eliminar políticas RLS primero
DROP POLICY IF EXISTS "Users can view customers from their branch" ON customers;
DROP POLICY IF EXISTS "Users can insert customers to their branch" ON customers;
DROP POLICY IF EXISTS "Users can update customers from their branch" ON customers;

DROP POLICY IF EXISTS "Users can view products from their branch" ON products;
DROP POLICY IF EXISTS "Users can manage products from their branch" ON products;

DROP POLICY IF EXISTS "Users can view services from their branch" ON services;
DROP POLICY IF EXISTS "Users can manage services from their branch" ON services;

DROP POLICY IF EXISTS "Users can view sales from their branch" ON sales;
DROP POLICY IF EXISTS "Users can create sales in their branch" ON sales;

DROP POLICY IF EXISTS "Users can view reservations from their branch" ON reservations;
DROP POLICY IF EXISTS "Users can manage reservations from their branch" ON reservations;

DROP POLICY IF EXISTS "Users can view expenses from their branch" ON expenses;
DROP POLICY IF EXISTS "Users can manage expenses from their branch" ON expenses;

-- Eliminar triggers
DROP TRIGGER IF EXISTS update_customers_updated_at ON customers;
DROP TRIGGER IF EXISTS update_products_updated_at ON products;
DROP TRIGGER IF EXISTS update_services_updated_at ON services;
DROP TRIGGER IF EXISTS update_reservations_updated_at ON reservations;

-- Eliminar funciones
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS get_user_branch_id() CASCADE;

-- Eliminar tablas en orden inverso (por foreign keys)
DROP TABLE IF EXISTS daily_summaries CASCADE;
DROP TABLE IF EXISTS sale_items CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS expenses CASCADE;
DROP TABLE IF EXISTS reservations CASCADE;
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS branches CASCADE;

-- Ahora puedes ejecutar schema.sql de nuevo
