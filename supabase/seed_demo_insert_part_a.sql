INSERT INTO public.point_views (
  name,
  region,
  city,
  description,
  latitude,
  longitude,
  created_by,
  image_urls
)
VALUES
  (
    'Tre Cime di Lavaredo',
    'Veneto',
    'Auronzo di Cadore',
    'Il circuito attorno alle tre cime è uno dei trekking più iconici delle Dolomiti: ghiaioni, panorami verticali e silenzio in alta quota. Meglio partire all''alba per la luce sulla parete nord.',
    46.6186,
    12.3028,
    NULL,
    ARRAY[
      'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?auto=format&fit=crop&w=1200&q=80'
    ]::text[]
  ),
  (
    'Sentiero degli Dei',
    'Campania',
    'Agerola',
    'Sentiero panoramico sopra la Costiera Amalfitana: mare a picco, piccoli casolari e curve che si aprono sul Tirreno. Scarpe da trekking consigliate; evita i mesi più caldi a metà giornata.',
    40.6280,
    14.4880,
    NULL,
    ARRAY[
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=1200&q=80'
    ]::text[]
  ),
  (
    'Belvedere Manarola',
    'Liguria',
    'Riomaggiore',
    'Scorcio classico delle Cinque Terre: case colorate sulla roccia e mare profondo. Al tramonto il paese si accende; arrivo comodo con treno + breve passeggiata.',
    44.1359,
    9.6848,
    NULL,
    ARRAY[
      'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1523906834658-6e66ef7f6087?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1583422409516-2895a77efded?auto=format&fit=crop&w=1200&q=80'
    ]::text[]
  ),
  (
    'Val d''Orcia da Pienza',
    'Toscana',
    'Pienza',
    'Colline ondulate, filari di cipressi e borghi rinascimentali: il cuore della Val d''Orcia è perfetto per foto ampie e passeggiate lente tra cantine e pecorino.',
    43.0778,
    11.6797,
    NULL,
    ARRAY[
      'https://images.unsplash.com/photo-1470071459604-3b5ec3c21f94?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1200&q=80'
    ]::text[]
  ),
  (
    'Campo Imperatore',
    'Abruzzo',
    'L''Aquila',
    'Altopiano granitico ai piedi del Gran Sasso: pascoli ampi, vento pulito e cieli limpidi. Sembra un altro pianeta rispetto alla costa adriatica.',
    42.4694,
    13.5658,
    NULL,
    ARRAY[
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1441974230531-20b1169a755b?auto=format&fit=crop&w=1200&q=80'
    ]::text[]
  );
