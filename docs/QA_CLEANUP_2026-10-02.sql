-- ลบเฉพาะห้อง QA ที่เจ้าของโปรเจกต์อนุมัติให้สร้างและลบทิ้งหลังทดสอบ
-- รันผ่าน Supabase SQL Editor ด้วยสิทธิ์ที่ลบแถวนี้ได้
DELETE FROM public.rooms
WHERE id = '2584f955-984e-447a-b3fd-b49274459896'
  AND name = 'QA_CratAble_20261002'
RETURNING id, name;

SELECT count(*) AS remaining_qa_rooms
FROM public.rooms
WHERE id = '2584f955-984e-447a-b3fd-b49274459896'
  AND name = 'QA_CratAble_20261002';
