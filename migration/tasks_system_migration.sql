-- ============================================================
-- MIGRACIÓN: Sistema de Tareas por Departamento con SLA
-- ============================================================
-- Objetivo:
--   1. Agregar encargado + SLA + color a designations (por cargo)
--   2. Permitir que employees tengan login propio (user_id)
--   3. Agregar scope por designación a users (encargado/empleado)
--   4. Crear tabla tasks dedicada con relojes independientes por tarea
--
-- EJECUTAR EN LOS 4 ESQUEMAS: stg, sde, sdo, rom
--
-- Uso:
--   Reemplazar {{SCHEMA}} por el esquema correspondiente y ejecutar
--   Ejemplo: psql -d victorpos -c "$(sed 's/{{SCHEMA}}/stg/g' tasks_system_migration.sql)"
-- ============================================================

-- ============================================================
-- PASO 1: Extender tabla designations (SLA + encargado + color)
-- ============================================================

ALTER TABLE {{SCHEMA}}.designations
  ADD COLUMN IF NOT EXISTS manager_user_id UUID,
  ADD COLUMN IF NOT EXISTS sla_days INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS sla_hours INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sla_minutes INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS color_hex VARCHAR(9) DEFAULT '#EC4899';

COMMENT ON COLUMN {{SCHEMA}}.designations.manager_user_id IS 'User ID del encargado de este cargo/departamento';
COMMENT ON COLUMN {{SCHEMA}}.designations.sla_days IS 'Días del SLA para completar una tarea asignada a este cargo';
COMMENT ON COLUMN {{SCHEMA}}.designations.sla_hours IS 'Horas adicionales del SLA';
COMMENT ON COLUMN {{SCHEMA}}.designations.sla_minutes IS 'Minutos adicionales del SLA';
COMMENT ON COLUMN {{SCHEMA}}.designations.color_hex IS 'Color identificador del departamento para la UI';

-- ============================================================
-- PASO 2: Extender tabla employees (vínculo opcional con un user)
-- ============================================================

ALTER TABLE {{SCHEMA}}.employees
  ADD COLUMN IF NOT EXISTS user_id UUID,
  ADD COLUMN IF NOT EXISTS can_login BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN {{SCHEMA}}.employees.user_id IS 'User ID asociado al empleado si se le dio credenciales de acceso';
COMMENT ON COLUMN {{SCHEMA}}.employees.can_login IS 'TRUE si el empleado tiene credenciales activas en el sistema';

CREATE INDEX IF NOT EXISTS idx_employees_user_id ON {{SCHEMA}}.employees(user_id) WHERE user_id IS NOT NULL;

-- ============================================================
-- PASO 3: Extender tabla users (scope por designación)
-- Nota: users es tabla pública (no por esquema), ejecutar UNA SOLA VEZ
-- Para evitar duplicar, se usa IF NOT EXISTS
-- ============================================================

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS scoped_designation_id INT,
  ADD COLUMN IF NOT EXISTS linked_employee_id UUID;

COMMENT ON COLUMN public.users.scoped_designation_id IS 'Si está presente, el user solo ve datos de esta designación (encargado o empleado)';
COMMENT ON COLUMN public.users.linked_employee_id IS 'Si el user representa a un empleado, su ID aquí';

-- ============================================================
-- PASO 4: Crear tabla tasks
-- ============================================================

CREATE TABLE IF NOT EXISTS {{SCHEMA}}.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id UUID NOT NULL,
  designation_id INT NOT NULL,
  assigned_to_user_id UUID,
  assigned_to_employee_id UUID,
  assigned_by_user_id UUID,
  assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  due_at TIMESTAMP NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pendiente',
  completed_at TIMESTAMP,
  completion_note TEXT,
  branch_id VARCHAR(10) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT tasks_status_check CHECK (status IN ('pendiente','en_progreso','completada','vencida'))
);

COMMENT ON TABLE {{SCHEMA}}.tasks IS 'Tareas asignadas a empleados con reloj independiente (SLA) por tarea';
COMMENT ON COLUMN {{SCHEMA}}.tasks.assigned_at IS 'Momento en que se asignó al empleado actual (se resetea si hay reasignación)';
COMMENT ON COLUMN {{SCHEMA}}.tasks.due_at IS 'Fecha límite calculada: assigned_at + SLA del cargo';
COMMENT ON COLUMN {{SCHEMA}}.tasks.status IS 'pendiente | en_progreso | completada | vencida';

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_tasks_reservation ON {{SCHEMA}}.tasks(reservation_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_user ON {{SCHEMA}}.tasks(assigned_to_user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_employee ON {{SCHEMA}}.tasks(assigned_to_employee_id);
CREATE INDEX IF NOT EXISTS idx_tasks_designation ON {{SCHEMA}}.tasks(designation_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status_due ON {{SCHEMA}}.tasks(status, due_at);
CREATE INDEX IF NOT EXISTS idx_tasks_branch ON {{SCHEMA}}.tasks(branch_id);

-- Trigger para auto-actualizar updated_at
CREATE OR REPLACE FUNCTION {{SCHEMA}}.tasks_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_tasks_update_timestamp ON {{SCHEMA}}.tasks;
CREATE TRIGGER trg_tasks_update_timestamp
  BEFORE UPDATE ON {{SCHEMA}}.tasks
  FOR EACH ROW
  EXECUTE FUNCTION {{SCHEMA}}.tasks_update_timestamp();

-- ============================================================
-- PASO 5: Verificación de la migración
-- ============================================================

-- Verificar columnas nuevas en designations
-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_schema = '{{SCHEMA}}' AND table_name = 'designations'
--   AND column_name IN ('manager_user_id','sla_days','sla_hours','sla_minutes','color_hex');

-- Verificar tabla tasks
-- SELECT COUNT(*) FROM {{SCHEMA}}.tasks;  -- Debe retornar 0

-- Verificar columnas en users (solo ejecutar una vez en public)
-- SELECT column_name FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = 'users'
--   AND column_name IN ('scoped_designation_id','linked_employee_id');
