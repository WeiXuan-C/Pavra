-- =====================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Report Issues System
-- =====================================

-- =====================================
-- REPORT_ISSUES TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.report_issues ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "report_issues_select_all" ON public.report_issues;
DROP POLICY IF EXISTS "report_issues_insert_authenticated" ON public.report_issues;
DROP POLICY IF EXISTS "report_issues_update_own_draft" ON public.report_issues;
DROP POLICY IF EXISTS "report_issues_update_authority_review" ON public.report_issues;
DROP POLICY IF EXISTS "report_issues_delete_own_draft" ON public.report_issues;
DROP POLICY IF EXISTS "report_issues_service_all" ON public.report_issues;

-- 1. SELECT Policy

-- 所有认证用户可以查看已提交的报告（submitted, reviewed）
-- 用户可以查看自己的所有报告（包括 draft）
-- Authority 和 Developer 可以查看所有报告
CREATE POLICY "report_issues_select_all" ON public.report_issues
  FOR SELECT
  TO authenticated
  USING (
    -- 查看已提交的报告（非 draft 且未删除）
    (status IN ('submitted', 'reviewed') AND is_deleted = FALSE)
    -- 用户可以查看自己的所有报告
    OR created_by = (SELECT auth.uid())
    -- Authority 和 Developer 可以查看所有
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) 
        AND role IN ('authority', 'developer')
    )
  );

-- 2. INSERT Policy

-- 所有认证用户可以创建报告
CREATE POLICY "report_issues_insert_authenticated" ON public.report_issues
  FOR INSERT
  TO authenticated
  WITH CHECK (
    created_by = (SELECT auth.uid())
  );

-- 3. UPDATE Policies

-- 用户可以更新自己的 draft 状态报告
CREATE POLICY "report_issues_update_own_draft" ON public.report_issues
  FOR UPDATE
  TO authenticated
  USING (
    created_by = (SELECT auth.uid())
    AND status = 'draft'
  )
  WITH CHECK (
    created_by = (SELECT auth.uid())
    AND status IN ('draft', 'submitted')  -- 可以从 draft 提交到 submitted
  );

-- Authority 可以审核报告（更新 status, reviewed_by, reviewed_comment, reviewed_at）
CREATE POLICY "report_issues_update_authority_review" ON public.report_issues
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) 
        AND role IN ('authority', 'developer')
    )
    AND status IN ('submitted', 'reviewed')
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) 
        AND role IN ('authority', 'developer')
    )
  );

-- 4. DELETE Policy

-- 用户可以软删除自己的 draft 报告
CREATE POLICY "report_issues_delete_own_draft" ON public.report_issues
  FOR DELETE
  TO authenticated
  USING (
    created_by = (SELECT auth.uid())
    AND status = 'draft'
  );

-- 5. Service Role Policy

-- Service role 可以完全管理 report_issues
CREATE POLICY "report_issues_service_all" ON public.report_issues
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================
-- ISSUE_PHOTOS TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.issue_photos ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "issue_photos_select_all" ON public.issue_photos;
DROP POLICY IF EXISTS "issue_photos_insert_own_issue" ON public.issue_photos;
DROP POLICY IF EXISTS "issue_photos_insert_authority" ON public.issue_photos;
DROP POLICY IF EXISTS "issue_photos_update_own_issue" ON public.issue_photos;
DROP POLICY IF EXISTS "issue_photos_delete_own_issue" ON public.issue_photos;
DROP POLICY IF EXISTS "issue_photos_service_all" ON public.issue_photos;

-- 1. SELECT Policy

-- 用户可以查看与可见报告关联的照片
CREATE POLICY "issue_photos_select_all" ON public.issue_photos
  FOR SELECT
  TO authenticated
  USING (
    is_deleted = FALSE
    AND EXISTS (
      SELECT 1 FROM public.report_issues
      WHERE id = issue_photos.issue_id
        AND (
          -- 已提交的报告
          (status IN ('submitted', 'reviewed') AND is_deleted = FALSE)
          -- 或者是自己创建的报告
          OR created_by = (SELECT auth.uid())
          -- 或者是 Authority/Developer
          OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = (SELECT auth.uid()) 
              AND role IN ('authority', 'developer')
          )
        )
    )
  );

-- 2. INSERT Policies

-- 用户可以为自己的报告上传照片
CREATE POLICY "issue_photos_insert_own_issue" ON public.issue_photos
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.report_issues
      WHERE id = issue_photos.issue_id
        AND created_by = (SELECT auth.uid())
        AND status = 'draft'
    )
  );

-- Authority 可以为任何报告上传审核照片
CREATE POLICY "issue_photos_insert_authority" ON public.issue_photos
  FOR INSERT
  TO authenticated
  WITH CHECK (
    photo_type = 'reviewed'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) 
        AND role IN ('authority', 'developer')
    )
  );

-- 3. UPDATE Policy

-- 用户可以更新自己报告的照片（仅 draft 状态）
CREATE POLICY "issue_photos_update_own_issue" ON public.issue_photos
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.report_issues
      WHERE id = issue_photos.issue_id
        AND created_by = (SELECT auth.uid())
        AND status = 'draft'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.report_issues
      WHERE id = issue_photos.issue_id
        AND created_by = (SELECT auth.uid())
        AND status = 'draft'
    )
  );

-- 4. DELETE Policy

-- 用户可以删除自己报告的照片（仅 draft 状态）
CREATE POLICY "issue_photos_delete_own_issue" ON public.issue_photos
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.report_issues
      WHERE id = issue_photos.issue_id
        AND created_by = (SELECT auth.uid())
        AND status = 'draft'
    )
  );

-- 5. Service Role Policy

-- Service role 可以完全管理 issue_photos
CREATE POLICY "issue_photos_service_all" ON public.issue_photos
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================
-- ISSUE_TYPES TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.issue_types ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "issue_types_select_all" ON public.issue_types;
DROP POLICY IF EXISTS "issue_types_insert_authority" ON public.issue_types;
DROP POLICY IF EXISTS "issue_types_update_authority" ON public.issue_types;
DROP POLICY IF EXISTS "issue_types_delete_authority" ON public.issue_types;
DROP POLICY IF EXISTS "issue_types_service_all" ON public.issue_types;

-- 1. SELECT Policy

-- 所有认证用户可以查看所有 issue types
CREATE POLICY "issue_types_select_all" ON public.issue_types
  FOR SELECT
  TO authenticated
  USING (is_deleted = FALSE);

-- 2. INSERT Policy

-- 只有 Authority 和 Developer 可以创建 issue types
CREATE POLICY "issue_types_insert_authority" ON public.issue_types
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) 
        AND role IN ('authority', 'developer')
    )
  );

-- 3. UPDATE Policy

-- 只有 Authority 和 Developer 可以更新 issue types
CREATE POLICY "issue_types_update_authority" ON public.issue_types
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) 
        AND role IN ('authority', 'developer')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) 
        AND role IN ('authority', 'developer')
    )
  );

-- 4. DELETE Policy

-- 只有 Authority 和 Developer 可以删除 issue types
CREATE POLICY "issue_types_delete_authority" ON public.issue_types
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) 
        AND role IN ('authority', 'developer')
    )
  );

-- 5. Service Role Policy

-- Service role 可以完全管理 issue_types
CREATE POLICY "issue_types_service_all" ON public.issue_types
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================
-- ISSUE_VOTES TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.issue_votes ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "issue_votes_select_all" ON public.issue_votes;
DROP POLICY IF EXISTS "issue_votes_insert_own" ON public.issue_votes;
DROP POLICY IF EXISTS "issue_votes_update_own" ON public.issue_votes;
DROP POLICY IF EXISTS "issue_votes_delete_own" ON public.issue_votes;
DROP POLICY IF EXISTS "issue_votes_service_all" ON public.issue_votes;

-- 1. SELECT Policy

-- 用户可以查看所有投票（用于显示统计）
-- Developer 可以查看所有详细投票信息
CREATE POLICY "issue_votes_select_all" ON public.issue_votes
  FOR SELECT
  TO authenticated
  USING (
    -- 用户可以查看自己的投票
    user_id = (SELECT auth.uid())
    -- Developer 可以查看所有
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) AND role = 'developer'
    )
  );

-- 2. INSERT Policy

-- 用户可以为已提交的报告投票
CREATE POLICY "issue_votes_insert_own" ON public.issue_votes
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1 FROM public.report_issues
      WHERE id = issue_votes.issue_id
        AND status IN ('submitted', 'reviewed')
        AND is_deleted = FALSE
    )
  );

-- 3. UPDATE Policy

-- 用户可以更新自己的投票
CREATE POLICY "issue_votes_update_own" ON public.issue_votes
  FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

-- 4. DELETE Policy

-- 用户可以删除自己的投票
CREATE POLICY "issue_votes_delete_own" ON public.issue_votes
  FOR DELETE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- 5. Service Role Policy

-- Service role 可以完全管理 issue_votes
CREATE POLICY "issue_votes_service_all" ON public.issue_votes
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================
-- AI_DETECTION TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.ai_detection ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "ai_detection_select_all" ON public.ai_detection;
DROP POLICY IF EXISTS "ai_detection_insert_system" ON public.ai_detection;
DROP POLICY IF EXISTS "ai_detection_update_system" ON public.ai_detection;
DROP POLICY IF EXISTS "ai_detection_delete_developer" ON public.ai_detection;
DROP POLICY IF EXISTS "ai_detection_service_all" ON public.ai_detection;

-- 1. SELECT Policy

-- 用户可以查看与可见报告关联的 AI 检测结果
CREATE POLICY "ai_detection_select_all" ON public.ai_detection
  FOR SELECT
  TO authenticated
  USING (
    is_deleted = FALSE
    AND EXISTS (
      SELECT 1 FROM public.report_issues
      WHERE id = ai_detection.issue_id
        AND (
          -- 已提交的报告
          (status IN ('submitted', 'reviewed') AND is_deleted = FALSE)
          -- 或者是自己创建的报告
          OR created_by = (SELECT auth.uid())
          -- 或者是 Authority/Developer
          OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = (SELECT auth.uid()) 
              AND role IN ('authority', 'developer')
          )
        )
    )
  );

-- 2. INSERT Policy

-- 系统可以插入 AI 检测结果（通过 service_role 或触发器）
CREATE POLICY "ai_detection_insert_system" ON public.ai_detection
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 3. UPDATE Policy

-- 系统可以更新 AI 检测结果
CREATE POLICY "ai_detection_update_system" ON public.ai_detection
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 4. DELETE Policy

-- 只有 Developer 可以删除 AI 检测结果
CREATE POLICY "ai_detection_delete_developer" ON public.ai_detection
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) AND role = 'developer'
    )
  );

-- 5. Service Role Policy

-- Service role 可以完全管理 ai_detection
CREATE POLICY "ai_detection_service_all" ON public.ai_detection
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================
-- AI_DESCRIPTIONS TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.ai_descriptions ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "ai_descriptions_select_all" ON public.ai_descriptions;
DROP POLICY IF EXISTS "ai_descriptions_insert_system" ON public.ai_descriptions;
DROP POLICY IF EXISTS "ai_descriptions_update_system" ON public.ai_descriptions;
DROP POLICY IF EXISTS "ai_descriptions_delete_developer" ON public.ai_descriptions;
DROP POLICY IF EXISTS "ai_descriptions_service_all" ON public.ai_descriptions;

-- 1. SELECT Policy

-- 用户可以查看与可见报告关联的 AI 描述
CREATE POLICY "ai_descriptions_select_all" ON public.ai_descriptions
  FOR SELECT
  TO authenticated
  USING (
    is_deleted = FALSE
    AND EXISTS (
      SELECT 1 FROM public.report_issues
      WHERE id = ai_descriptions.issue_id
        AND (
          -- 已提交的报告
          (status IN ('submitted', 'reviewed') AND is_deleted = FALSE)
          -- 或者是自己创建的报告
          OR created_by = (SELECT auth.uid())
          -- 或者是 Authority/Developer
          OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = (SELECT auth.uid()) 
              AND role IN ('authority', 'developer')
          )
        )
    )
  );

-- 2. INSERT Policy

-- 系统可以插入 AI 描述（通过 service_role 或触发器）
CREATE POLICY "ai_descriptions_insert_system" ON public.ai_descriptions
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 3. UPDATE Policy

-- 系统可以更新 AI 描述
CREATE POLICY "ai_descriptions_update_system" ON public.ai_descriptions
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 4. DELETE Policy

-- 只有 Developer 可以删除 AI 描述
CREATE POLICY "ai_descriptions_delete_developer" ON public.ai_descriptions
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) AND role = 'developer'
    )
  );

-- 5. Service Role Policy

-- Service role 可以完全管理 ai_descriptions
CREATE POLICY "ai_descriptions_service_all" ON public.ai_descriptions
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================
-- POLICY 说明
-- =====================================

-- Report Issues
COMMENT ON POLICY "report_issues_select_all" ON public.report_issues IS 
  '所有认证用户可以查看已提交的报告，用户可以查看自己的所有报告，Authority/Developer 可以查看所有';

COMMENT ON POLICY "report_issues_insert_authenticated" ON public.report_issues IS 
  '所有认证用户可以创建报告';

COMMENT ON POLICY "report_issues_update_own_draft" ON public.report_issues IS 
  '用户可以更新自己的 draft 状态报告';

COMMENT ON POLICY "report_issues_update_authority_review" ON public.report_issues IS 
  'Authority 可以审核报告';

COMMENT ON POLICY "report_issues_delete_own_draft" ON public.report_issues IS 
  '用户可以删除自己的 draft 报告';

COMMENT ON POLICY "report_issues_service_all" ON public.report_issues IS 
  'Service role 可以完全管理 report_issues';

-- Issue Photos
COMMENT ON POLICY "issue_photos_select_all" ON public.issue_photos IS 
  '用户可以查看与可见报告关联的照片';

COMMENT ON POLICY "issue_photos_insert_own_issue" ON public.issue_photos IS 
  '用户可以为自己的报告上传照片';

COMMENT ON POLICY "issue_photos_insert_authority" ON public.issue_photos IS 
  'Authority 可以为任何报告上传审核照片';

COMMENT ON POLICY "issue_photos_update_own_issue" ON public.issue_photos IS 
  '用户可以更新自己报告的照片（仅 draft 状态）';

COMMENT ON POLICY "issue_photos_delete_own_issue" ON public.issue_photos IS 
  '用户可以删除自己报告的照片（仅 draft 状态）';

COMMENT ON POLICY "issue_photos_service_all" ON public.issue_photos IS 
  'Service role 可以完全管理 issue_photos';

-- Issue Types
COMMENT ON POLICY "issue_types_select_all" ON public.issue_types IS 
  '所有认证用户可以查看所有 issue types';

COMMENT ON POLICY "issue_types_insert_authority" ON public.issue_types IS 
  '只有 Authority 和 Developer 可以创建 issue types';

COMMENT ON POLICY "issue_types_update_authority" ON public.issue_types IS 
  '只有 Authority 和 Developer 可以更新 issue types';

COMMENT ON POLICY "issue_types_delete_authority" ON public.issue_types IS 
  '只有 Authority 和 Developer 可以删除 issue types';

COMMENT ON POLICY "issue_types_service_all" ON public.issue_types IS 
  'Service role 可以完全管理 issue_types';

-- Issue Votes
COMMENT ON POLICY "issue_votes_select_all" ON public.issue_votes IS 
  '用户可以查看自己的投票，Developer 可以查看所有';

COMMENT ON POLICY "issue_votes_insert_own" ON public.issue_votes IS 
  '用户可以为已提交的报告投票';

COMMENT ON POLICY "issue_votes_update_own" ON public.issue_votes IS 
  '用户可以更新自己的投票';

COMMENT ON POLICY "issue_votes_delete_own" ON public.issue_votes IS 
  '用户可以删除自己的投票';

COMMENT ON POLICY "issue_votes_service_all" ON public.issue_votes IS 
  'Service role 可以完全管理 issue_votes';

-- AI Detection
COMMENT ON POLICY "ai_detection_select_all" ON public.ai_detection IS 
  '用户可以查看与可见报告关联的 AI 检测结果';

COMMENT ON POLICY "ai_detection_insert_system" ON public.ai_detection IS 
  '系统可以插入 AI 检测结果';

COMMENT ON POLICY "ai_detection_update_system" ON public.ai_detection IS 
  '系统可以更新 AI 检测结果';

COMMENT ON POLICY "ai_detection_delete_developer" ON public.ai_detection IS 
  '只有 Developer 可以删除 AI 检测结果';

COMMENT ON POLICY "ai_detection_service_all" ON public.ai_detection IS 
  'Service role 可以完全管理 ai_detection';

-- AI Descriptions
COMMENT ON POLICY "ai_descriptions_select_all" ON public.ai_descriptions IS 
  '用户可以查看与可见报告关联的 AI 描述';

COMMENT ON POLICY "ai_descriptions_insert_system" ON public.ai_descriptions IS 
  '系统可以插入 AI 描述';

COMMENT ON POLICY "ai_descriptions_update_system" ON public.ai_descriptions IS 
  '系统可以更新 AI 描述';

COMMENT ON POLICY "ai_descriptions_delete_developer" ON public.ai_descriptions IS 
  '只有 Developer 可以删除 AI 描述';

COMMENT ON POLICY "ai_descriptions_service_all" ON public.ai_descriptions IS 
  'Service role 可以完全管理 ai_descriptions';
