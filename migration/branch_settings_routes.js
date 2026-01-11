// ============================================================
// ENDPOINTS: Branch Settings
// Agregar este código a tu servidor Node.js/Express
// ============================================================

const express = require('express');
const router = express.Router();

// Middleware de autenticación (ajusta según tu implementación)
const { authenticateToken, getBranchId } = require('./middleware/auth');

// ============================================================
// GET /api/branch-settings
// Obtener configuración de la sucursal actual
// ============================================================
router.get('/branch-settings', authenticateToken, async (req, res) => {
    try {
        const branchId = getBranchId(req);

        if (!branchId) {
            return res.status(400).json({
                success: false,
                error: 'Branch ID requerido'
            });
        }

        const result = await req.db.query(
            `SELECT * FROM branch_settings WHERE branch_id = $1`,
            [branchId]
        );

        if (result.rows.length === 0) {
            // Crear configuración por defecto si no existe
            const defaultSettings = await req.db.query(
                `INSERT INTO branch_settings (branch_id, company_name, branch_name, city)
                 VALUES ($1, 'Victor Guzman Fotografía', $1, $1)
                 RETURNING *`,
                [branchId]
            );
            return res.json({
                success: true,
                branch_settings: defaultSettings.rows[0]
            });
        }

        res.json({
            success: true,
            branch_settings: result.rows[0]
        });

    } catch (error) {
        console.error('Error obteniendo branch settings:', error);
        res.status(500).json({
            success: false,
            error: 'Error interno del servidor'
        });
    }
});

// ============================================================
// GET /api/branch-settings/:branchId
// Obtener configuración de una sucursal específica
// ============================================================
router.get('/branch-settings/:branchId', authenticateToken, async (req, res) => {
    try {
        const { branchId } = req.params;

        const result = await req.db.query(
            `SELECT * FROM branch_settings WHERE branch_id = $1`,
            [branchId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Configuración no encontrada'
            });
        }

        res.json({
            success: true,
            branch_settings: result.rows[0]
        });

    } catch (error) {
        console.error('Error obteniendo branch settings:', error);
        res.status(500).json({
            success: false,
            error: 'Error interno del servidor'
        });
    }
});

// ============================================================
// GET /api/branch-settings/all
// Obtener todas las configuraciones de sucursales
// ============================================================
router.get('/branch-settings/all', authenticateToken, async (req, res) => {
    try {
        const result = await req.db.query(
            `SELECT * FROM branch_settings ORDER BY branch_name`
        );

        res.json({
            success: true,
            branches: result.rows
        });

    } catch (error) {
        console.error('Error obteniendo branch settings:', error);
        res.status(500).json({
            success: false,
            error: 'Error interno del servidor'
        });
    }
});

// ============================================================
// PUT /api/branch-settings
// Actualizar configuración de la sucursal actual
// ============================================================
router.put('/branch-settings', authenticateToken, async (req, res) => {
    try {
        const branchId = getBranchId(req);

        if (!branchId) {
            return res.status(400).json({
                success: false,
                error: 'Branch ID requerido'
            });
        }

        const {
            company_name,
            rnc,
            logo_url,
            branch_name,
            city,
            address,
            phone,
            whatsapp,
            email,
            website,
            instagram,
            facebook,
            show_logo_in_invoice,
            logo_on_right,
            invoice_footer_text
        } = req.body;

        const result = await req.db.query(
            `UPDATE branch_settings SET
                company_name = COALESCE($1, company_name),
                rnc = COALESCE($2, rnc),
                logo_url = COALESCE($3, logo_url),
                branch_name = COALESCE($4, branch_name),
                city = COALESCE($5, city),
                address = COALESCE($6, address),
                phone = COALESCE($7, phone),
                whatsapp = $8,
                email = $9,
                website = $10,
                instagram = $11,
                facebook = $12,
                show_logo_in_invoice = COALESCE($13, show_logo_in_invoice),
                logo_on_right = COALESCE($14, logo_on_right),
                invoice_footer_text = $15,
                updated_at = NOW()
            WHERE branch_id = $16
            RETURNING *`,
            [
                company_name,
                rnc,
                logo_url,
                branch_name,
                city,
                address,
                phone,
                whatsapp,
                email,
                website,
                instagram,
                facebook,
                show_logo_in_invoice,
                logo_on_right,
                invoice_footer_text,
                branchId
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Configuración no encontrada'
            });
        }

        res.json({
            success: true,
            branch_settings: result.rows[0],
            message: 'Configuración actualizada correctamente'
        });

    } catch (error) {
        console.error('Error actualizando branch settings:', error);
        res.status(500).json({
            success: false,
            error: 'Error interno del servidor'
        });
    }
});

// ============================================================
// PUT /api/branch-settings/upsert
// Crear o actualizar configuración (upsert)
// ============================================================
router.put('/branch-settings/upsert', authenticateToken, async (req, res) => {
    try {
        const branchId = req.body.branch_id || getBranchId(req);

        if (!branchId) {
            return res.status(400).json({
                success: false,
                error: 'Branch ID requerido'
            });
        }

        const {
            company_name = 'Victor Guzman Fotografía',
            rnc = '',
            logo_url,
            branch_name = '',
            city = '',
            address = '',
            phone = '',
            whatsapp,
            email,
            website,
            instagram,
            facebook,
            show_logo_in_invoice = true,
            logo_on_right = false,
            invoice_footer_text
        } = req.body;

        const result = await req.db.query(
            `INSERT INTO branch_settings (
                branch_id, company_name, rnc, logo_url, branch_name, city,
                address, phone, whatsapp, email, website, instagram, facebook,
                show_logo_in_invoice, logo_on_right, invoice_footer_text
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
            ON CONFLICT (branch_id) DO UPDATE SET
                company_name = EXCLUDED.company_name,
                rnc = EXCLUDED.rnc,
                logo_url = EXCLUDED.logo_url,
                branch_name = EXCLUDED.branch_name,
                city = EXCLUDED.city,
                address = EXCLUDED.address,
                phone = EXCLUDED.phone,
                whatsapp = EXCLUDED.whatsapp,
                email = EXCLUDED.email,
                website = EXCLUDED.website,
                instagram = EXCLUDED.instagram,
                facebook = EXCLUDED.facebook,
                show_logo_in_invoice = EXCLUDED.show_logo_in_invoice,
                logo_on_right = EXCLUDED.logo_on_right,
                invoice_footer_text = EXCLUDED.invoice_footer_text,
                updated_at = NOW()
            RETURNING *`,
            [
                branchId,
                company_name,
                rnc,
                logo_url,
                branch_name,
                city,
                address,
                phone,
                whatsapp,
                email,
                website,
                instagram,
                facebook,
                show_logo_in_invoice,
                logo_on_right,
                invoice_footer_text
            ]
        );

        res.json({
            success: true,
            branch_settings: result.rows[0],
            message: 'Configuración guardada correctamente'
        });

    } catch (error) {
        console.error('Error en upsert branch settings:', error);
        res.status(500).json({
            success: false,
            error: 'Error interno del servidor'
        });
    }
});

// ============================================================
// POST /api/branch-settings
// Crear configuración inicial
// ============================================================
router.post('/branch-settings', authenticateToken, async (req, res) => {
    try {
        const branchId = req.body.branch_id || getBranchId(req);

        if (!branchId) {
            return res.status(400).json({
                success: false,
                error: 'Branch ID requerido'
            });
        }

        // Verificar si ya existe
        const existing = await req.db.query(
            `SELECT id FROM branch_settings WHERE branch_id = $1`,
            [branchId]
        );

        if (existing.rows.length > 0) {
            return res.status(409).json({
                success: false,
                error: 'La configuración ya existe. Use PUT para actualizar.'
            });
        }

        const {
            company_name = 'Victor Guzman Fotografía',
            rnc = '',
            logo_url,
            branch_name = '',
            city = '',
            address = '',
            phone = '',
            whatsapp,
            email,
            website,
            instagram,
            facebook,
            show_logo_in_invoice = true,
            logo_on_right = false,
            invoice_footer_text
        } = req.body;

        const result = await req.db.query(
            `INSERT INTO branch_settings (
                branch_id, company_name, rnc, logo_url, branch_name, city,
                address, phone, whatsapp, email, website, instagram, facebook,
                show_logo_in_invoice, logo_on_right, invoice_footer_text
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
            RETURNING *`,
            [
                branchId,
                company_name,
                rnc,
                logo_url,
                branch_name,
                city,
                address,
                phone,
                whatsapp,
                email,
                website,
                instagram,
                facebook,
                show_logo_in_invoice,
                logo_on_right,
                invoice_footer_text
            ]
        );

        res.status(201).json({
            success: true,
            branch_settings: result.rows[0],
            message: 'Configuración creada correctamente'
        });

    } catch (error) {
        console.error('Error creando branch settings:', error);
        res.status(500).json({
            success: false,
            error: 'Error interno del servidor'
        });
    }
});

module.exports = router;

// ============================================================
// INTEGRACIÓN EN TU APP.JS O INDEX.JS
// ============================================================
/*
// En tu archivo principal del servidor, agregar:

const branchSettingsRoutes = require('./routes/branch_settings_routes');

// Registrar las rutas
app.use('/api', branchSettingsRoutes);
*/
