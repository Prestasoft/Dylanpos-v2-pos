-- =====================================================
-- ESQUEMA DE BASE DE DATOS SUPABASE
-- Victor Guzman Fotografía - Sistema POS
-- Migración desde Firebase Realtime Database
-- =====================================================

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLA: branches (Sucursales)
-- Reemplaza los 4 proyectos Firebase separados
-- =====================================================
CREATE TABLE branches (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    short_name TEXT NOT NULL,
    city TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    logo_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insertar las 4 sucursales
INSERT INTO branches (id, name, short_name, city, address) VALUES
    ('sde', 'Victor Guzman Fotografía', 'SDE', 'Santo Domingo Este', 'Av. San Vicente de Paul'),
    ('stg', 'Victor Guzman Fotografía', 'Santiago', 'Santiago', ''),
    ('sdo', 'Victor Guzman Fotografía', 'Sto Dgo', 'Santo Domingo', ''),
    ('rom', 'Victor Guzman Fotografía', 'La Romana', 'La Romana', '');

-- =====================================================
-- TABLA: users (Usuarios)
-- Extiende auth.users de Supabase
-- =====================================================
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    branch_id TEXT REFERENCES branches(id),
    email TEXT NOT NULL,
    name TEXT,
    phone TEXT,
    role TEXT DEFAULT 'user',
    permissions JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABLA: customers (Clientes)
-- =====================================================
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id TEXT NOT NULL REFERENCES branches(id),
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    due_amount DECIMAL(12,2) DEFAULT 0,
    previous_due DECIMAL(12,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABLA: categories (Categorías de productos)
-- =====================================================
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id TEXT NOT NULL REFERENCES branches(id),
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABLA: products (Productos/Vestidos)
-- =====================================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id TEXT NOT NULL REFERENCES branches(id),
    category_id UUID REFERENCES categories(id),
    name TEXT NOT NULL,
    description TEXT,
    barcode TEXT,
    price DECIMAL(12,2) NOT NULL DEFAULT 0,
    purchase_price DECIMAL(12,2) DEFAULT 0,
    stock INTEGER DEFAULT 0,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABLA: services (Paquetes de Servicio)
-- Equivalente a Admin Panel/services en Firebase
-- =====================================================
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id TEXT NOT NULL REFERENCES branches(id),
    type TEXT,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    subcategory TEXT,
    description TEXT,
    price DECIMAL(12,2) NOT NULL DEFAULT 0,
    duration INTEGER,
    components JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABLA: reservations (Reservaciones)
-- =====================================================
CREATE TABLE reservations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id TEXT NOT NULL REFERENCES branches(id),
    customer_id UUID REFERENCES customers(id),
    service_id UUID REFERENCES services(id),
    date DATE NOT NULL,
    time TIME,
    status TEXT DEFAULT 'pending',
    notes TEXT,
    total DECIMAL(12,2) DEFAULT 0,
    deposit DECIMAL(12,2) DEFAULT 0,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABLA: sales (Ventas)
-- =====================================================
CREATE TABLE sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id TEXT NOT NULL REFERENCES branches(id),
    customer_id UUID REFERENCES customers(id),
    invoice_number TEXT,
    date TIMESTAMPTZ DEFAULT NOW(),
    subtotal DECIMAL(12,2) DEFAULT 0,
    discount DECIMAL(12,2) DEFAULT 0,
    tax DECIMAL(12,2) DEFAULT 0,
    total DECIMAL(12,2) NOT NULL DEFAULT 0,
    paid_amount DECIMAL(12,2) DEFAULT 0,
    due_amount DECIMAL(12,2) DEFAULT 0,
    payment_method TEXT,
    status TEXT DEFAULT 'completed',
    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABLA: sale_items (Items de venta)
-- =====================================================
CREATE TABLE sale_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    service_id UUID REFERENCES services(id),
    name TEXT NOT NULL,
    quantity INTEGER DEFAULT 1,
    unit_price DECIMAL(12,2) NOT NULL,
    total DECIMAL(12,2) NOT NULL
);

-- =====================================================
-- TABLA: expenses (Gastos)
-- =====================================================
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id TEXT NOT NULL REFERENCES branches(id),
    category TEXT NOT NULL,
    description TEXT,
    amount DECIMAL(12,2) NOT NULL,
    date DATE DEFAULT CURRENT_DATE,
    payment_method TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABLA: daily_summaries (Resúmenes diarios/Cuadres)
-- =====================================================
CREATE TABLE daily_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id TEXT NOT NULL REFERENCES branches(id),
    date DATE NOT NULL,
    total_sales DECIMAL(12,2) DEFAULT 0,
    total_expenses DECIMAL(12,2) DEFAULT 0,
    cash_amount DECIMAL(12,2) DEFAULT 0,
    card_amount DECIMAL(12,2) DEFAULT 0,
    transfer_amount DECIMAL(12,2) DEFAULT 0,
    notes TEXT,
    closed_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(branch_id, date)
);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- Cada usuario solo ve datos de su sucursal
-- =====================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_summaries ENABLE ROW LEVEL SECURITY;

-- Función para obtener el branch_id del usuario actual
CREATE OR REPLACE FUNCTION get_user_branch_id()
RETURNS TEXT AS $$
BEGIN
    RETURN (
        SELECT branch_id
        FROM users
        WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Políticas RLS para cada tabla
-- Customers
CREATE POLICY "Users can view customers from their branch"
    ON customers FOR SELECT
    USING (branch_id = get_user_branch_id());

CREATE POLICY "Users can insert customers to their branch"
    ON customers FOR INSERT
    WITH CHECK (branch_id = get_user_branch_id());

CREATE POLICY "Users can update customers from their branch"
    ON customers FOR UPDATE
    USING (branch_id = get_user_branch_id());

-- Products
CREATE POLICY "Users can view products from their branch"
    ON products FOR SELECT
    USING (branch_id = get_user_branch_id());

CREATE POLICY "Users can manage products from their branch"
    ON products FOR ALL
    USING (branch_id = get_user_branch_id());

-- Services
CREATE POLICY "Users can view services from their branch"
    ON services FOR SELECT
    USING (branch_id = get_user_branch_id());

CREATE POLICY "Users can manage services from their branch"
    ON services FOR ALL
    USING (branch_id = get_user_branch_id());

-- Sales
CREATE POLICY "Users can view sales from their branch"
    ON sales FOR SELECT
    USING (branch_id = get_user_branch_id());

CREATE POLICY "Users can create sales in their branch"
    ON sales FOR INSERT
    WITH CHECK (branch_id = get_user_branch_id());

-- Reservations
CREATE POLICY "Users can view reservations from their branch"
    ON reservations FOR SELECT
    USING (branch_id = get_user_branch_id());

CREATE POLICY "Users can manage reservations from their branch"
    ON reservations FOR ALL
    USING (branch_id = get_user_branch_id());

-- Expenses
CREATE POLICY "Users can view expenses from their branch"
    ON expenses FOR SELECT
    USING (branch_id = get_user_branch_id());

CREATE POLICY "Users can manage expenses from their branch"
    ON expenses FOR ALL
    USING (branch_id = get_user_branch_id());

-- =====================================================
-- ÍNDICES para mejor rendimiento
-- =====================================================
CREATE INDEX idx_customers_branch ON customers(branch_id);
CREATE INDEX idx_products_branch ON products(branch_id);
CREATE INDEX idx_services_branch ON services(branch_id);
CREATE INDEX idx_sales_branch ON sales(branch_id);
CREATE INDEX idx_sales_date ON sales(date);
CREATE INDEX idx_reservations_branch ON reservations(branch_id);
CREATE INDEX idx_reservations_date ON reservations(date);
CREATE INDEX idx_expenses_branch ON expenses(branch_id);

-- =====================================================
-- TRIGGERS para updated_at automático
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_services_updated_at
    BEFORE UPDATE ON services
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reservations_updated_at
    BEFORE UPDATE ON reservations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
