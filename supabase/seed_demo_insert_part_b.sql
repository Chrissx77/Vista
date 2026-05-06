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
