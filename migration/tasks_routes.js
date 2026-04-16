// ============================================================
// ENDPOINTS: Tasks (Sistema de Tareas por Departamento con SLA)
// Agregar este código al servidor Node.js/Express en /var/www/victorpos-api
// ============================================================
//
// Ruta del archivo en servidor: /var/www/victorpos-api/src/routes/tasks.js
//
// Registro en index.js:
//   const tasksRoutes = require('./routes/tasks');
//   app.use('/api/hrm', tasksRoutes);
//
// Patrón seguido (idéntico a branch_settings_routes.js y daily-transactions.js):
//   - Autenticación vía authenticateToken middleware
//   - Schema routing vía X-Branch-Id header (getBranchId)
//   - req.db.query para queries parametrizadas
//   - Respuesta: { success, data|resource, message|error }
//   - NO usa Firebase, solo PostgreSQL
// ============================================================

const express = require('express');
const router = express.Router();

// Middleware de autenticación (igual que en branch_settings_routes.js)
const { authenticateToken, getBranchId } = require('./middleware/auth');

// ============================================================
// Helper: construir nombre de tabla con schema dinámico
// ============================================================
function tbl(branchId, table) {
  // branchId viene validado como stg|sde|sdo|rom
  return `${branchId}.${table}`;
}

// ============================================================
// Helper: validar branchId (evita SQL injection de schema)
// ============================================================
const ALLOWED_SCHEMAS = ['stg', 'sde', 'sdo', 'rom'];
function validateBranch(branchId) {
  if (!branchId || !ALLOWED_SCHEMAS.includes(branchId)) {
    return null;
  }
  return branchId;
}

// ============================================================
// Helper: calcular due_at = assigned_at + SLA del cargo
// ============================================================
async function computeDueAt(db, branchId, designationId, assignedAt = null) {
  const result = await db.query(
    `SELECT sla_days, sla_hours, sla_minutes
     FROM ${tbl(branchId, 'designations')}
     WHERE designation_id = $1`,
    [designationId]
  );
  if (result.rows.length === 0) {
    throw new Error(`Designación ${designationId} no encontrada`);
  }
  const sla = result.rows[0];
  const days = parseInt(sla.sla_days) || 0;
  const hours = parseInt(sla.sla_hours) || 0;
  const minutes = parseInt(sla.sla_minutes) || 0;
  const base = assignedAt ? `$1::timestamp` : 'CURRENT_TIMESTAMP';
  const sqlInterval = `INTERVAL '${days} days ${hours} hours ${minutes} minutes'`;
  const params = assignedAt ? [assignedAt] : [];
  const dueResult = await db.query(`SELECT (${base} + ${sqlInterval}) AS due_at`, params);
  return {
    due_at: dueResult.rows[0].due_at,
    sla_days: sla.sla_days,
    sla_hours: sla.sla_hours,
    sla_minutes: sla.sla_minutes,
  };
}

// ============================================================
// GET /api/hrm/tasks
// Lista tareas con filtros. Si el user tiene scoped_designation_id,
// auto-filtra por esa designación.
// Query params: assigned_to_user_id, designation_id, status, date_from, date_to
// ============================================================
router.get('/tasks', authenticateToken, async (req, res) => {
  try {
    const branchId = validateBranch(getBranchId(req));
    if (!branchId) {
      return res.status(400).json({ success: false, error: 'Branch ID inválido o ausente' });
    }

    const {
      assigned_to_user_id,
      designation_id,
      status,
      date_from,
      date_to,
    } = req.query;

    // Auto-filtro por scoped_designation_id del user
    const userScopedDesignation = req.user && req.user.scoped_designation_id;

    const where = ['branch_id = $1'];
    const params = [branchId];
    let pIdx = 2;

    if (assigned_to_user_id) {
      where.push(`assigned_to_user_id = $${pIdx++}`);
      params.push(assigned_to_user_id);
    }
    const effectiveDesignationId = designation_id || userScopedDesignation;
    if (effectiveDesignationId) {
      where.push(`designation_id = $${pIdx++}`);
      params.push(effectiveDesignationId);
    }
    if (status) {
      where.push(`status = $${pIdx++}`);
      params.push(status);
    }
    if (date_from) {
      where.push(`assigned_at >= $${pIdx++}`);
      params.push(date_from);
    }
    if (date_to) {
      where.push(`assigned_at <= $${pIdx++}`);
      params.push(date_to);
    }

    const result = await req.db.query(
      `SELECT t.*,
              d.designation AS designation_name,
              d.color_hex AS designation_color,
              r.nota AS reservation_nota
       FROM ${tbl(branchId, 'tasks')} t
       LEFT JOIN ${tbl(branchId, 'designations')} d ON d.designation_id = t.designation_id
       LEFT JOIN ${tbl(branchId, 'reservations')} r ON r.id = t.reservation_id
       WHERE ${where.join(' AND ')}
       ORDER BY t.due_at ASC`,
      params
    );

    res.json({
      success: true,
      data: { tasks: result.rows },
    });
  } catch (error) {
    console.error('Error GET /tasks:', error);
    res.status(500).json({ success: false, error: error.message || 'Error interno del servidor' });
  }
});

// ============================================================
// GET /api/hrm/tasks/my
// Tareas del user autenticado (vista empleado)
// Incluye pendientes + vencidas, ordenadas por due_at ASC
// ============================================================
router.get('/tasks/my', authenticateToken, async (req, res) => {
  try {
    const branchId = validateBranch(getBranchId(req));
    if (!branchId) {
      return res.status(400).json({ success: false, error: 'Branch ID inválido o ausente' });
    }
    if (!req.user || !req.user.id) {
      return res.status(401).json({ success: false, error: 'Usuario no autenticado' });
    }

    const result = await req.db.query(
      `SELECT t.*,
              d.designation AS designation_name,
              d.color_hex AS designation_color,
              r.nota AS reservation_nota
       FROM ${tbl(branchId, 'tasks')} t
       LEFT JOIN ${tbl(branchId, 'designations')} d ON d.designation_id = t.designation_id
       LEFT JOIN ${tbl(branchId, 'reservations')} r ON r.id = t.reservation_id
       WHERE t.assigned_to_user_id = $1
         AND t.branch_id = $2
         AND (t.status IN ('pendiente','en_progreso','vencida')
           OR (t.status = 'completada' AND t.completed_at::date = CURRENT_DATE))
       ORDER BY
         CASE t.status
           WHEN 'vencida' THEN 0
           WHEN 'pendiente' THEN 1
           WHEN 'en_progreso' THEN 2
           WHEN 'completada' THEN 3
         END,
         t.due_at ASC`,
      [req.user.id, branchId]
    );

    res.json({
      success: true,
      data: { tasks: result.rows },
    });
  } catch (error) {
    console.error('Error GET /tasks/my:', error);
    res.status(500).json({ success: false, error: error.message || 'Error interno del servidor' });
  }
});

// ============================================================
// GET /api/hrm/tasks/department-status
// Estado del equipo del encargado: empleados + KPIs por empleado
// Solo accesible si el user tiene scoped_designation_id (encargado)
// ============================================================
router.get('/tasks/department-status', authenticateToken, async (req, res) => {
  try {
    const branchId = validateBranch(getBranchId(req));
    if (!branchId) {
      return res.status(400).json({ success: false, error: 'Branch ID inválido o ausente' });
    }

    const designationId = req.query.designation_id || (req.user && req.user.scoped_designation_id);
    if (!designationId) {
      return res.status(400).json({
        success: false,
        error: 'designation_id requerido o el user debe tener scoped_designation_id',
      });
    }

    // Empleados del departamento + KPIs agregados
    const result = await req.db.query(
      `SELECT
         e.id AS employee_id,
         e.name AS employee_name,
         e.user_id,
         e.can_login,
         COALESCE(stats.pendientes, 0) AS pendientes,
         COALESCE(stats.en_progreso, 0) AS en_progreso,
         COALESCE(stats.vencidas, 0) AS vencidas,
         COALESCE(stats.completadas_hoy, 0) AS completadas_hoy,
         CASE
           WHEN COALESCE(stats.vencidas, 0) > 0 THEN 'atrasado'
           WHEN COALESCE(stats.en_progreso, 0) + COALESCE(stats.pendientes, 0) = 0 THEN 'sin_tareas'
           WHEN stats.proxima_a_vencer THEN 'por_vencer'
           ELSE 'al_dia'
         END AS estado
       FROM ${tbl(branchId, 'employees')} e
       LEFT JOIN (
         SELECT
           assigned_to_employee_id,
           SUM(CASE WHEN status = 'pendiente' THEN 1 ELSE 0 END) AS pendientes,
           SUM(CASE WHEN status = 'en_progreso' THEN 1 ELSE 0 END) AS en_progreso,
           SUM(CASE WHEN status = 'vencida' THEN 1 ELSE 0 END) AS vencidas,
           SUM(CASE WHEN status = 'completada' AND completed_at::date = CURRENT_DATE THEN 1 ELSE 0 END) AS completadas_hoy,
           BOOL_OR(status IN ('pendiente','en_progreso') AND due_at < CURRENT_TIMESTAMP + INTERVAL '1 hour') AS proxima_a_vencer
         FROM ${tbl(branchId, 'tasks')}
         WHERE branch_id = $1
         GROUP BY assigned_to_employee_id
       ) stats ON stats.assigned_to_employee_id = e.id
       WHERE e.designation_id = $2
       ORDER BY estado DESC, e.name ASC`,
      [branchId, designationId]
    );

    // KPIs totales del departamento
    const totalsResult = await req.db.query(
      `SELECT
         SUM(CASE WHEN status = 'pendiente' THEN 1 ELSE 0 END) AS total_pendientes,
         SUM(CASE WHEN status = 'en_progreso' THEN 1 ELSE 0 END) AS total_en_progreso,
         SUM(CASE WHEN status = 'vencida' THEN 1 ELSE 0 END) AS total_vencidas,
         SUM(CASE WHEN status = 'completada' AND completed_at::date = CURRENT_DATE THEN 1 ELSE 0 END) AS total_completadas_hoy
       FROM ${tbl(branchId, 'tasks')}
       WHERE branch_id = $1 AND designation_id = $2`,
      [branchId, designationId]
    );

    res.json({
      success: true,
      data: {
        employees: result.rows,
        totals: totalsResult.rows[0] || {},
      },
    });
  } catch (error) {
    console.error('Error GET /tasks/department-status:', error);
    res.status(500).json({ success: false, error: error.message || 'Error interno del servidor' });
  }
});

// ============================================================
// POST /api/hrm/tasks
// Crear tarea. Calcula due_at = NOW() + SLA del cargo.
// ============================================================
router.post('/tasks', authenticateToken, async (req, res) => {
  try {
    const branchId = validateBranch(getBranchId(req));
    if (!branchId) {
      return res.status(400).json({ success: false, error: 'Branch ID inválido o ausente' });
    }

    const {
      reservation_id,
      designation_id,
      assigned_to_user_id,
      assigned_to_employee_id,
    } = req.body;

    if (!reservation_id || !designation_id) {
      return res.status(400).json({
        success: false,
        error: 'reservation_id y designation_id son requeridos',
      });
    }

    const { due_at } = await computeDueAt(req.db, branchId, designation_id);
    const assignedBy = req.user && req.user.id;

    const result = await req.db.query(
      `INSERT INTO ${tbl(branchId, 'tasks')} (
         reservation_id, designation_id, assigned_to_user_id, assigned_to_employee_id,
         assigned_by_user_id, due_at, branch_id
       ) VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        reservation_id,
        designation_id,
        assigned_to_user_id || null,
        assigned_to_employee_id || null,
        assignedBy || null,
        due_at,
        branchId,
      ]
    );

    res.status(201).json({
      success: true,
      data: { task: result.rows[0] },
      message: 'Tarea creada correctamente',
    });
  } catch (error) {
    console.error('Error POST /tasks:', error);
    res.status(500).json({ success: false, error: error.message || 'Error interno del servidor' });
  }
});

// ============================================================
// PUT /api/hrm/tasks/:id
// Reasigna empleado O actualiza nota.
// CRÍTICO: Si cambia assigned_to_user_id o assigned_to_employee_id,
// resetea assigned_at y recalcula due_at (el SLA arranca de cero).
// ============================================================
router.put('/tasks/:id', authenticateToken, async (req, res) => {
  try {
    const branchId = validateBranch(getBranchId(req));
    if (!branchId) {
      return res.status(400).json({ success: false, error: 'Branch ID inválido o ausente' });
    }

    const { id } = req.params;
    const {
      assigned_to_user_id,
      assigned_to_employee_id,
      status,
      completion_note,
    } = req.body;

    // Leer tarea actual para comparar
    const currentResult = await req.db.query(
      `SELECT * FROM ${tbl(branchId, 'tasks')} WHERE id = $1 AND branch_id = $2`,
      [id, branchId]
    );
    if (currentResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Tarea no encontrada' });
    }
    const current = currentResult.rows[0];

    // Detectar reasignación
    const isReassign =
      (assigned_to_user_id !== undefined && assigned_to_user_id !== current.assigned_to_user_id) ||
      (assigned_to_employee_id !== undefined && assigned_to_employee_id !== current.assigned_to_employee_id);

    let newDueAt = current.due_at;
    let newAssignedAt = current.assigned_at;
    if (isReassign) {
      const { due_at } = await computeDueAt(req.db, branchId, current.designation_id);
      newDueAt = due_at;
      newAssignedAt = new Date();
    }

    const effectiveUserId = assigned_to_user_id !== undefined ? assigned_to_user_id : current.assigned_to_user_id;
    const effectiveEmployeeId = assigned_to_employee_id !== undefined ? assigned_to_employee_id : current.assigned_to_employee_id;
    const effectiveStatus = status || current.status;
    const effectiveNote = completion_note !== undefined ? completion_note : current.completion_note;

    const result = await req.db.query(
      `UPDATE ${tbl(branchId, 'tasks')} SET
         assigned_to_user_id = $1,
         assigned_to_employee_id = $2,
         assigned_at = $3,
         due_at = $4,
         status = $5,
         completion_note = $6,
         assigned_by_user_id = COALESCE($7, assigned_by_user_id)
       WHERE id = $8 AND branch_id = $9
       RETURNING *`,
      [
        effectiveUserId,
        effectiveEmployeeId,
        newAssignedAt,
        newDueAt,
        effectiveStatus,
        effectiveNote,
        (req.user && req.user.id) || null,
        id,
        branchId,
      ]
    );

    res.json({
      success: true,
      data: { task: result.rows[0] },
      message: isReassign ? 'Tarea reasignada (SLA reiniciado)' : 'Tarea actualizada',
    });
  } catch (error) {
    console.error('Error PUT /tasks/:id:', error);
    res.status(500).json({ success: false, error: error.message || 'Error interno del servidor' });
  }
});

// ============================================================
// POST /api/hrm/tasks/:id/complete
// Marca la tarea como completada con nota opcional
// ============================================================
router.post('/tasks/:id/complete', authenticateToken, async (req, res) => {
  try {
    const branchId = validateBranch(getBranchId(req));
    if (!branchId) {
      return res.status(400).json({ success: false, error: 'Branch ID inválido o ausente' });
    }

    const { id } = req.params;
    const { completion_note } = req.body;

    const result = await req.db.query(
      `UPDATE ${tbl(branchId, 'tasks')} SET
         status = 'completada',
         completed_at = CURRENT_TIMESTAMP,
         completion_note = COALESCE($1, completion_note)
       WHERE id = $2 AND branch_id = $3
       RETURNING *`,
      [completion_note || null, id, branchId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Tarea no encontrada' });
    }

    res.json({
      success: true,
      data: { task: result.rows[0] },
      message: 'Tarea completada',
    });
  } catch (error) {
    console.error('Error POST /tasks/:id/complete:', error);
    res.status(500).json({ success: false, error: error.message || 'Error interno del servidor' });
  }
});

// ============================================================
// POST /api/hrm/tasks/mark-overdue
// Marca como 'vencida' las tareas pendientes/en_progreso con due_at pasado.
// Pensado para ejecutarse vía cron cada 5 minutos o al cargar el dashboard.
// ============================================================
router.post('/tasks/mark-overdue', authenticateToken, async (req, res) => {
  try {
    const branchId = validateBranch(getBranchId(req));
    if (!branchId) {
      return res.status(400).json({ success: false, error: 'Branch ID inválido o ausente' });
    }

    const result = await req.db.query(
      `UPDATE ${tbl(branchId, 'tasks')} SET status = 'vencida'
       WHERE status IN ('pendiente','en_progreso')
         AND due_at < CURRENT_TIMESTAMP
         AND branch_id = $1
       RETURNING id`,
      [branchId]
    );

    res.json({
      success: true,
      data: { marked_overdue: result.rows.length },
    });
  } catch (error) {
    console.error('Error POST /tasks/mark-overdue:', error);
    res.status(500).json({ success: false, error: error.message || 'Error interno del servidor' });
  }
});

// ============================================================
// DELETE /api/hrm/tasks/:id
// Elimina una tarea (usar solo cuando se cancela la reserva)
// ============================================================
router.delete('/tasks/:id', authenticateToken, async (req, res) => {
  try {
    const branchId = validateBranch(getBranchId(req));
    if (!branchId) {
      return res.status(400).json({ success: false, error: 'Branch ID inválido o ausente' });
    }

    const { id } = req.params;
    const result = await req.db.query(
      `DELETE FROM ${tbl(branchId, 'tasks')} WHERE id = $1 AND branch_id = $2 RETURNING id`,
      [id, branchId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Tarea no encontrada' });
    }

    res.json({ success: true, message: 'Tarea eliminada' });
  } catch (error) {
    console.error('Error DELETE /tasks/:id:', error);
    res.status(500).json({ success: false, error: error.message || 'Error interno del servidor' });
  }
});

module.exports = router;

// ============================================================
// INTEGRACIÓN EN INDEX.JS DEL SERVIDOR
// ============================================================
/*
  En /var/www/victorpos-api/src/index.js agregar:

  const tasksRoutes = require('./routes/tasks');
  app.use('/api/hrm', tasksRoutes);

  Luego reiniciar:
  pm2 restart victorpos-api
*/
