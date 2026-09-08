update storage.buckets
set allowed_mime_types = array[
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp'
]
where id = 'background-images';
