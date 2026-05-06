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
