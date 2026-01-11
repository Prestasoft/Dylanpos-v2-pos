-- ============================================================
-- TABLA: branch_settings
-- Configuración de sucursales para facturas
-- ============================================================

CREATE TABLE IF NOT EXISTS branch_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id TEXT NOT NULL UNIQUE,

    -- Información del negocio
    company_name TEXT NOT NULL DEFAULT 'Victor Guzman Fotografía',
    rnc TEXT DEFAULT '',
    logo_url TEXT,

    -- Información de la sucursal
    branch_name TEXT DEFAULT '',
    city TEXT DEFAULT '',
    address TEXT DEFAULT '',
    phone TEXT DEFAULT '',
    whatsapp TEXT,

    -- Contacto
    email TEXT,
    website TEXT,
    instagram TEXT,
    facebook TEXT,

    -- Configuración de factura
    show_logo_in_invoice BOOLEAN DEFAULT true,
    logo_on_right BOOLEAN DEFAULT false,
    invoice_footer_text TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índice por branch_id para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_branch_settings_branch_id ON branch_settings(branch_id);

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_branch_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_branch_settings_updated_at
    BEFORE UPDATE ON branch_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_branch_settings_updated_at();

-- Insertar configuración por defecto para las 4 sucursales
INSERT INTO branch_settings (branch_id, company_name, branch_name, city)
VALUES
    ('sde', 'Victor Guzman Fotografía', 'Santo Domingo Este', 'Santo Domingo Este'),
    ('stg', 'Victor Guzman Fotografía', 'Santiago', 'Santiago'),
    ('sdo', 'Victor Guzman Fotografía', 'Santo Domingo', 'Santo Domingo'),
    ('rom', 'Victor Guzman Fotografía', 'La Romana', 'La Romana')
ON CONFLICT (branch_id) DO NOTHING;

-- ============================================================
-- COMENTARIOS
-- ============================================================
COMMENT ON TABLE branch_settings IS 'Configuración de sucursales para mostrar en facturas';
COMMENT ON COLUMN branch_settings.branch_id IS 'ID de la sucursal (sde, stg, sdo, rom)';
COMMENT ON COLUMN branch_settings.rnc IS 'Registro Nacional del Contribuyente';
COMMENT ON COLUMN branch_settings.show_logo_in_invoice IS 'Mostrar logo en la factura';
COMMENT ON COLUMN branch_settings.logo_on_right IS 'Posición del logo (true=derecha, false=izquierda)';
