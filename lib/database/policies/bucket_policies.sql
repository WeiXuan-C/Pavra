CREATE POLICY "Allow authenticated users to update issue photos" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'issue-photos') WITH CHECK (bucket_id = 'issue-photos');

CREATE POLICY "Allow authenticated users to upload issue photos" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'issue-photos');

CREATE POLICY "Allow public read access to issue photos" ON storage.objects FOR SELECT TO public USING (bucket_id = 'issue-photos');

CREATE POLICY "Allow authenticated users to delete issue photos" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'issue-photos');