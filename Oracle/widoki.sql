CREATE OR REPLACE VIEW v_rezerwacje AS
SELECT 
  r.rezerwacja_id,
  f.tytul,
  rep.data_rozpoczecia AS data_seansu,
  b.rzad,
  b.miejsce,
  r.cena_laczna,
  r.uzytkownik
FROM 
  Rezerwacja_table r
  JOIN Repertuar_table rep ON r.repertuar_ref = REF(rep)
  JOIN Film_table       f   ON rep.film_ref      = REF(f)
  CROSS JOIN TABLE(r.bilety) b
WHERE
  r.czy_anulowane = 0;
