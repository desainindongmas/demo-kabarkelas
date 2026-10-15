-- =====================================================================
-- KabarKelas: skema awal Supabase (STARTER untuk produksi)
-- Demo web saat ini belum terhubung ke Supabase.
-- Jalankan di project DEV lebih dulu (Supabase Dashboard > SQL Editor),
-- uji dengan beberapa akun berbeda peran, baru pakai di produksi.
-- Semua tabel memakai Row Level Security (RLS) dan dipisah per sekolah.
-- =====================================================================

-- ---------- Tipe dan tabel inti ----------
create type public.user_role as enum ('admin','kepsek','guru','ortu','yayasan','satpam');

create table public.schools (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  kkm         int  not null default 70 check (kkm between 0 and 100),
  grade_scale text not null default 'n100',
  created_at  timestamptz not null default now()
);

create table public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  school_id  uuid not null references public.schools(id) on delete cascade,
  role       public.user_role not null,
  full_name  text not null,
  created_at timestamptz not null default now()
);

create table public.classes (
  id        uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  name      text not null,
  year      text not null,
  unique (school_id, name, year)
);

create table public.students (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null references public.schools(id) on delete cascade,
  class_id   uuid references public.classes(id) on delete set null,
  nis        text not null,
  full_name  text not null,
  gender     char(1) check (gender in ('L','P')),
  status     text not null default 'Aktif' check (status in ('Aktif','Nonaktif')),
  photo_path text,                       -- foto resmi, hanya diubah admin
  unique (school_id, nis)
);

create table public.guardians (          -- orang tua/wali dan siswanya
  user_id    uuid not null references auth.users(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  relation   text,
  primary key (user_id, student_id)
);

-- ---------- Akademik ----------
create table public.attendance_students (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null references public.schools(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  day        date not null,
  status     char(1) not null check (status in ('H','S','I','A')),
  unique (student_id, day)
);

create table public.grades (
  id          uuid primary key default gen_random_uuid(),
  school_id   uuid not null references public.schools(id) on delete cascade,
  student_id  uuid not null references public.students(id) on delete cascade,
  subject     text not null,
  assessment  text not null,
  score       numeric(5,2) not null check (score between 0 and 100),
  assessed_on date not null default current_date
);

create table public.tasks (
  id                uuid primary key default gen_random_uuid(),
  school_id         uuid not null references public.schools(id) on delete cascade,
  class_id          uuid not null references public.classes(id) on delete cascade,
  subject           text not null,
  kind              text not null check (kind in ('PR','Quiz','Ulangan Harian','Proyek')),
  title             text not null,
  description       text,
  due_on            date not null,
  remind            boolean not null default true,
  scores_published  boolean not null default false,
  created_by        uuid default auth.uid() references auth.users(id)
);

create table public.task_results (
  task_id    uuid not null references public.tasks(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  school_id  uuid not null references public.schools(id) on delete cascade,
  status     char(1) not null default 'B' check (status in ('S','T','B')), -- sudah, terlambat, belum
  score      numeric(5,2) check (score between 0 and 100),
  primary key (task_id, student_id)
);

-- ---------- Komunikasi ----------
create table public.announcements (
  id              uuid primary key default gen_random_uuid(),
  school_id       uuid not null references public.schools(id) on delete cascade,
  title           text not null,
  body            text not null,
  category        text not null default 'Umum',
  audience        text not null default 'Semua' check (audience in ('Semua','Guru','Orang Tua','Siswa')),
  published_on    date not null default current_date,
  event_on        date,
  pinned          boolean not null default false,
  status          text not null default 'Terbit' check (status in ('Terbit','Draf')),
  photo_path      text,
  attachment_path text
);

create table public.uniform_weekly (
  school_id uuid not null references public.schools(id) on delete cascade,
  weekday   int  not null check (weekday between 1 and 5),   -- 1 = Senin
  uniform   text not null,
  note      text,
  primary key (school_id, weekday)
);

create table public.uniform_overrides (   -- menggantikan jadwal tetap pada tanggal tertentu
  id        uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  on_date   date not null,
  uniform   text not null,
  reason    text,
  unique (school_id, on_date)
);

-- ---------- Guru ----------
create table public.teacher_attendance (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null references public.schools(id) on delete cascade,
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  day        date not null,
  status     char(1) not null check (status in ('H','S','I','A')),
  checked_in time,
  source     text not null default 'Mandiri',
  unique (teacher_id, day)
);

create table public.leave_requests (
  id           uuid primary key default gen_random_uuid(),
  school_id    uuid not null references public.schools(id) on delete cascade,
  teacher_id   uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  kind         text not null,
  from_date    date not null,
  to_date      date not null check (to_date >= from_date),
  reason       text not null,
  photo_path   text,
  letter_path  text,
  status       text not null default 'Menunggu' check (status in ('Menunggu','Disetujui','Ditolak')),
  decided_by   uuid references auth.users(id),
  decision_note text
);

-- ---------- Antar jemput ----------
create table public.pickup_persons (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null references public.schools(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  full_name  text not null,
  relation   text not null,
  phone      text,
  valid_on   date,                       -- null = penjemput tetap, isi tanggal = penjemput pengganti
  created_by uuid default auth.uid() references auth.users(id)
);

create table public.pickup_logs (        -- catatan bersifat tambah-saja (audit)
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null references public.schools(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  direction  char(1) not null check (direction in ('A','J')),    -- antar / jemput
  person_name text not null,
  relation   text not null,
  via        text not null check (via in ('QR','QR pengganti','Manual')),
  registered boolean not null default true,
  note       text,
  logged_at  timestamptz not null default now(),
  logged_by  uuid default auth.uid() references auth.users(id)
);

create table public.important_events (   -- pemicu notifikasi penting (rencana WhatsApp)
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null references public.schools(id) on delete cascade,
  kind       text not null check (kind in ('Tanpa QR','Di luar daftar','Terlambat >3 jam','Urgent')),
  message    text not null,
  student_id uuid references public.students(id) on delete set null,
  created_at timestamptz not null default now(),
  sent_at    timestamptz
);

-- ---------- Indeks ----------
create index on public.students (school_id, class_id);
create index on public.attendance_students (school_id, day);
create index on public.grades (student_id);
create index on public.tasks (school_id, due_on);
create index on public.pickup_logs (school_id, logged_at);
create index on public.guardians (student_id);

-- ---------- Fungsi bantu (dipakai kebijakan RLS) ----------
create or replace function public.my_school() returns uuid
language sql stable security definer set search_path = ''
as $$ select school_id from public.profiles where id = (select auth.uid()) $$;

create or replace function public.my_role() returns public.user_role
language sql stable security definer set search_path = ''
as $$ select role from public.profiles where id = (select auth.uid()) $$;

create or replace function public.is_guardian(sid uuid) returns boolean
language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.guardians g
                     where g.user_id = (select auth.uid()) and g.student_id = sid) $$;

revoke execute on function public.my_school(), public.my_role(), public.is_guardian(uuid) from public, anon;
grant  execute on function public.my_school(), public.my_role(), public.is_guardian(uuid) to authenticated;

-- ---------- Aktifkan RLS di SEMUA tabel ----------
alter table public.schools             enable row level security;
alter table public.profiles            enable row level security;
alter table public.classes             enable row level security;
alter table public.students            enable row level security;
alter table public.guardians           enable row level security;
alter table public.attendance_students enable row level security;
alter table public.grades              enable row level security;
alter table public.tasks               enable row level security;
alter table public.task_results        enable row level security;
alter table public.announcements       enable row level security;
alter table public.uniform_weekly      enable row level security;
alter table public.uniform_overrides   enable row level security;
alter table public.teacher_attendance  enable row level security;
alter table public.leave_requests      enable row level security;
alter table public.pickup_persons      enable row level security;
alter table public.pickup_logs         enable row level security;
alter table public.important_events    enable row level security;

-- ---------- Kebijakan ----------
-- Sekolah dan profil
create policy schools_read on public.schools for select to authenticated
  using (id = (select public.my_school()));
create policy schools_admin_update on public.schools for update to authenticated
  using (id = (select public.my_school()) and (select public.my_role()) = 'admin')
  with check (id = (select public.my_school()));

create policy profiles_read on public.profiles for select to authenticated
  using (id = (select auth.uid())
         or (school_id = (select public.my_school()) and (select public.my_role()) in ('admin','kepsek','yayasan')));

-- Kelas
create policy classes_read on public.classes for select to authenticated
  using (school_id = (select public.my_school()));
create policy classes_admin_write on public.classes for all to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) = 'admin')
  with check (school_id = (select public.my_school()) and (select public.my_role()) = 'admin');

-- Siswa: staf melihat seluruh sekolah, orang tua hanya anaknya, perubahan hanya admin
create policy students_staff_read on public.students for select to authenticated
  using (school_id = (select public.my_school())
         and (select public.my_role()) in ('admin','kepsek','guru','yayasan','satpam'));
create policy students_parent_read on public.students for select to authenticated
  using (public.is_guardian(id));
create policy students_admin_write on public.students for all to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) = 'admin')
  with check (school_id = (select public.my_school()) and (select public.my_role()) = 'admin');

-- Wali murid
create policy guardians_read on public.guardians for select to authenticated
  using (user_id = (select auth.uid()) or (select public.my_role()) = 'admin');
create policy guardians_admin_write on public.guardians for all to authenticated
  using ((select public.my_role()) = 'admin')
  with check ((select public.my_role()) = 'admin');

-- Absensi siswa
create policy att_read on public.attendance_students for select to authenticated
  using (school_id = (select public.my_school())
         and ((select public.my_role()) in ('admin','kepsek','guru','yayasan') or public.is_guardian(student_id)));
create policy att_write on public.attendance_students for all to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) in ('admin','guru'))
  with check (school_id = (select public.my_school()) and (select public.my_role()) in ('admin','guru'));

-- Nilai
create policy grades_read on public.grades for select to authenticated
  using (school_id = (select public.my_school())
         and ((select public.my_role()) in ('admin','kepsek','guru','yayasan') or public.is_guardian(student_id)));
create policy grades_write on public.grades for all to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) in ('admin','guru'))
  with check (school_id = (select public.my_school()) and (select public.my_role()) in ('admin','guru'));

-- Tugas dan quiz
create policy tasks_staff_read on public.tasks for select to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) in ('admin','kepsek','guru','yayasan'));
create policy tasks_parent_read on public.tasks for select to authenticated
  using (exists (select 1 from public.guardians g join public.students s on s.id = g.student_id
                 where g.user_id = (select auth.uid()) and s.class_id = tasks.class_id));
create policy tasks_write on public.tasks for all to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) in ('admin','guru'))
  with check (school_id = (select public.my_school()) and (select public.my_role()) in ('admin','guru'));

create policy task_results_read on public.task_results for select to authenticated
  using (school_id = (select public.my_school())
         and ((select public.my_role()) in ('admin','kepsek','guru','yayasan') or public.is_guardian(student_id)));
create policy task_results_write on public.task_results for all to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) in ('admin','guru'))
  with check (school_id = (select public.my_school()) and (select public.my_role()) in ('admin','guru'));
-- Catatan: nilai quiz untuk orang tua sebaiknya dibaca lewat view/RPC yang memeriksa tasks.scores_published.

-- Pengumuman: yang terbit dan sesuai peran; admin mengelola semuanya
create policy ann_read on public.announcements for select to authenticated
  using (school_id = (select public.my_school())
         and ((select public.my_role()) = 'admin'
              or (status = 'Terbit'
                  and (audience = 'Semua'
                       or (select public.my_role()) in ('kepsek','yayasan')
                       or (audience = 'Guru' and (select public.my_role()) = 'guru')
                       or (audience = 'Orang Tua' and (select public.my_role()) = 'ortu')))));
create policy ann_admin_write on public.announcements for all to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) = 'admin')
  with check (school_id = (select public.my_school()) and (select public.my_role()) = 'admin');

-- Seragam
create policy uw_read on public.uniform_weekly for select to authenticated
  using (school_id = (select public.my_school()));
create policy uw_admin_write on public.uniform_weekly for all to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) = 'admin')
  with check (school_id = (select public.my_school()) and (select public.my_role()) = 'admin');
create policy uo_read on public.uniform_overrides for select to authenticated
  using (school_id = (select public.my_school()));
create policy uo_admin_write on public.uniform_overrides for all to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) = 'admin')
  with check (school_id = (select public.my_school()) and (select public.my_role()) = 'admin');

-- Absensi guru: guru melihat dan mengisi miliknya sendiri
create policy ta_read on public.teacher_attendance for select to authenticated
  using (school_id = (select public.my_school())
         and (teacher_id = (select auth.uid()) or (select public.my_role()) in ('admin','kepsek','yayasan')));
create policy ta_self_insert on public.teacher_attendance for insert to authenticated
  with check (school_id = (select public.my_school()) and teacher_id = (select auth.uid())
              and (select public.my_role()) = 'guru');
create policy ta_admin_write on public.teacher_attendance for all to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) = 'admin')
  with check (school_id = (select public.my_school()) and (select public.my_role()) = 'admin');

-- Izin guru: guru mengajukan, kepala sekolah memutuskan
create policy lr_read on public.leave_requests for select to authenticated
  using (school_id = (select public.my_school())
         and (teacher_id = (select auth.uid()) or (select public.my_role()) in ('admin','kepsek')));
create policy lr_insert on public.leave_requests for insert to authenticated
  with check (school_id = (select public.my_school()) and teacher_id = (select auth.uid())
              and (select public.my_role()) = 'guru' and status = 'Menunggu');
create policy lr_decide on public.leave_requests for update to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) = 'kepsek')
  with check (school_id = (select public.my_school()) and (select public.my_role()) = 'kepsek');

-- Penjemput: staf antar jemput dan orang tua melihat; admin mengelola; orang tua membuat penjemput pengganti
create policy pp_read on public.pickup_persons for select to authenticated
  using (school_id = (select public.my_school())
         and ((select public.my_role()) in ('admin','kepsek','satpam') or public.is_guardian(student_id)));
create policy pp_admin_write on public.pickup_persons for all to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) = 'admin')
  with check (school_id = (select public.my_school()) and (select public.my_role()) = 'admin');
create policy pp_parent_substitute_insert on public.pickup_persons for insert to authenticated
  with check (school_id = (select public.my_school()) and public.is_guardian(student_id) and valid_on is not null);
create policy pp_parent_substitute_delete on public.pickup_persons for delete to authenticated
  using (public.is_guardian(student_id) and valid_on is not null);

-- Log antar jemput: hanya security yang mencatat; tidak ada update atau delete
create policy pl_read on public.pickup_logs for select to authenticated
  using (school_id = (select public.my_school())
         and ((select public.my_role()) in ('admin','kepsek','satpam') or public.is_guardian(student_id)));
create policy pl_insert on public.pickup_logs for insert to authenticated
  with check (school_id = (select public.my_school()) and (select public.my_role()) = 'satpam');

-- Kejadian penting: staf membaca; penulisan lewat fungsi server (secret key)
create policy ie_read on public.important_events for select to authenticated
  using (school_id = (select public.my_school()) and (select public.my_role()) in ('admin','kepsek','satpam'));

-- ---------- Tahap berikutnya (di luar berkas ini) ----------
-- 1. Bucket Storage privat untuk foto siswa, lampiran izin, dan lampiran pengumuman,
--    dengan kebijakan Storage yang mengikuti school_id dan peran.
-- 2. Trigger/RPC: membuat baris important_events saat log 'Manual' atau penjemput tidak terdaftar.
-- 3. Verifikasi QR di server (Edge Function), bukan hanya di browser.
