update storage.buckets
set allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
where id in ('profile-images', 'user-gallery');;
