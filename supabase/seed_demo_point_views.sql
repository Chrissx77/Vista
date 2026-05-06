-- Dati dimostrativi per popolare l’app (punti panoramici italiani).
-- Idempotente: rimuove le righe demo per nome e reinserisce.
-- Esegui nel SQL Editor Supabase (o: supabase db execute) come postgres/service role.

BEGIN;

DELETE FROM public.point_views
WHERE name IN (
  'Tre Cime di Lavaredo',
  'Sentiero degli Dei',
  'Belvedere Manarola',
  'Val d''Orcia da Pienza',
  'Campo Imperatore',
  'Crateri sommitali dell''Etna',
  'Villa Rufolo — Terrazza dell''Infinito',
  'Monte Baldo — malga',
  'Costiera Amalfitana — Punta Campanella',
  'Castelluccio di Norcia — Fiorita'
);

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
  ),
  (
    'Crateri sommitali dell''Etna',
    'Sicilia',
    'Nicolosi',
    'Luna scenografica tra lava nera e fumarole: quota elevata e odore di zolfo. Controlla sempre allerte meteo e stato escursioni guidate.',
    37.7510,
    15.0044,
    NULL,
    ARRAY[
      'https://images.unsplash.com/photo-1526481280695-8c99fa79de69?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1446776653964-20c1d3a81b06?auto=format&fit=crop&w=1200&q=80'
    ]::text[]
  ),
  (
    'Villa Rufolo — Terrazza dell''Infinito',
    'Campania',
    'Ravello',
    'Giardini in quota sulla Costiera Amalfitana: glicini, archi mozzafiato e vista infinita sul mare. Luogo iconico per concerti estivi.',
    40.6490,
    14.6120,
    NULL,
    ARRAY[
      'https://images.unsplash.com/photo-1533104816934-15f23e96e632?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1523906834658-6e66ef7f6087?auto=format&fit=crop&w=1200&q=80'
    ]::text[]
  ),
  (
    'Monte Baldo — malga',
    'Veneto',
    'Malcesine',
    'Balcone naturale sul Lago di Garda: pascoli, malghe e sentieri per mountain bike o trekking leggero. Funivia da Malcesine per salire in quota velocemente.',
    45.5800,
    10.8380,
    NULL,
    ARRAY[
      'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=1200&q=80'
    ]::text[]
  ),
  (
    'Costiera Amalfitana — Punta Campanella',
    'Campania',
    'Massa Lubrense',
    'Promontorio tra golfo di Napoli e Salerno: sentieri costieri, faraglioni e mare turchese. Ideale al tramonto con brezza costante.',
    40.5869,
    14.3186,
    NULL,
    ARRAY[
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1437719417032-8595fd9e9dc6?auto=format&fit=crop&w=1200&q=80'
    ]::text[]
  ),
  (
    'Castelluccio di Norcia — Fiorita',
    'Umbria',
    'Norcia',
    'Piana alta tra lenticchie e fioriture primaverili: palette pastello incredibile tra fine maggio e luglio. Temperatura più fresca anche d''estate.',
    42.7714,
    13.2286,
    NULL,
    ARRAY[
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1470071459604-3b5ec3c21f94?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1490750967868-88aa4486c946?auto=format&fit=crop&w=1200&q=80'
    ]::text[]
  );

COMMIT;
