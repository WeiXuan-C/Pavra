-- =====================================
-- GET NEARBY ISSUES FUNCTION
-- =====================================
-- Returns report issues within a specified radius of a location
-- Uses Haversine formula for efficient geospatial queries

CREATE OR REPLACE FUNCTION public.get_nearby_issues(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  radius_meters DOUBLE PRECISION,
  issue_status TEXT DEFAULT 'submitted'
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  issue_type_ids UUID[],
  severity TEXT,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  status TEXT,
  created_at TIMESTAMPTZ,
  distance_miles DOUBLE PRECISION,
  photo_url TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ri.id,
    ri.title,
    ri.description,
    ri.issue_type_ids,
    ri.severity,
    ri.address,
    ri.latitude,
    ri.longitude,
    ri.status,
    ri.created_at,
    -- Calculate distance in miles using Haversine formula
    (
      3958.8 * acos(
        LEAST(1.0, GREATEST(-1.0,
          cos(radians(user_lat)) * 
          cos(radians(ri.latitude)) * 
          cos(radians(ri.longitude) - radians(user_lng)) + 
          sin(radians(user_lat)) * 
          sin(radians(ri.latitude))
        ))
      )
    ) AS distance_miles,
    -- Get primary photo or first photo
    (
      SELECT ip.photo_url 
      FROM public.issue_photos ip 
      WHERE ip.issue_id = ri.id 
        AND ip.is_deleted = FALSE
      ORDER BY ip.is_primary DESC, ip.created_at ASC
      LIMIT 1
    ) AS photo_url
  FROM public.report_issues ri
  WHERE 
    ri.status = issue_status
    AND ri.is_deleted = FALSE
    AND ri.latitude IS NOT NULL
    AND ri.longitude IS NOT NULL
    -- Bounding box filter for performance (approximate)
    AND ri.latitude BETWEEN (user_lat - (radius_meters / 111320.0)) 
                        AND (user_lat + (radius_meters / 111320.0))
    AND ri.longitude BETWEEN (user_lng - (radius_meters / (111320.0 * GREATEST(cos(radians(user_lat)), 0.001)))) 
                         AND (user_lng + (radius_meters / (111320.0 * GREATEST(cos(radians(user_lat)), 0.001))))
    -- Precise distance filter using Haversine
    AND (
      3958.8 * acos(
        LEAST(1.0, GREATEST(-1.0,
          cos(radians(user_lat)) * 
          cos(radians(ri.latitude)) * 
          cos(radians(ri.longitude) - radians(user_lng)) + 
          sin(radians(user_lat)) * 
          sin(radians(ri.latitude))
        ))
      )
    ) <= (radius_meters / 1609.34) -- Convert meters to miles
  ORDER BY distance_miles ASC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_nearby_issues(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT) TO authenticated;

-- Add function comment
COMMENT ON FUNCTION public.get_nearby_issues IS 'Returns report issues within a specified radius of a user location using Haversine formula. Optimized with bounding box pre-filtering.';
