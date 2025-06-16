CREATE OR REPLACE VIEW v_rezerwacje AS
 SELECT
  r.rezerwacja_id,
  f.tytul,
  rep.data_rozpoczecia AS data_seansu,
  b.rzad,
  b.miejsce,
  r.cena_laczna,
  r.uzytkownik
 FROM Rezerwacja_table r
 JOIN Repertuar_table rep ON r.repertuar_ref = REF(rep)
 JOIN Film_table f ON rep.film_ref = REF(f)
 CROSS JOIN TABLE(r.bilety) b
 WHERE r.czy_anulowane = 0
/

CREATE OR REPLACE VIEW vw_seanse AS
 SELECT
  f.tytul AS tytul,
  r.data_rozpoczecia AS data_rozpoczecia,
  SUM(
   CASE WHEN m.czy_zajete = 0 THEN 1 ELSE 0 END
  ) AS wolne_miejsca
 FROM Repertuar_table r
 JOIN Film_table f ON f.film_id = DEREF(r.film_ref).film_id
 CROSS JOIN TABLE(DEREF(r.sala_ref).miejsca) m
 GROUP BY
  f.tytul,
  r.data_rozpoczecia
/

CREATE OR REPLACE VIEW vw_popularnosc_filmow AS
WITH miejsca_seans AS (
  SELECT
    r.repertuar_id,
    COUNT(*) AS seats_total
  FROM Repertuar_table r
  JOIN Sala_table s ON r.sala_ref = REF(s)
  CROSS JOIN TABLE(s.miejsca) m
  GROUP BY r.repertuar_id
),
bilety_seans AS (
  SELECT
    rez.repertuar_ref.repertuar_id AS repertuar_id,
    COUNT(*) AS seats_taken
  FROM Rezerwacja_table rez
  JOIN TABLE(rez.bilety) b ON 1=1
  WHERE rez.czy_anulowane = 0
  GROUP BY rez.repertuar_ref.repertuar_id
)
SELECT
  f.film_id,
  f.tytul,
  TRUNC(r.data_rozpoczecia, 'IW') AS tyg_start,
  TRUNC(r.data_rozpoczecia, 'IW') + 6 AS tyg_koniec,
  ROUND(
    NVL(SUM(bt.seats_taken), 0) / NULLIF(SUM(mt.seats_total), 0) * 100,
    2
  ) AS proc_zapelnienia
FROM Repertuar_table r
JOIN Film_table f ON r.film_ref = REF(f)
JOIN miejsca_seans mt ON mt.repertuar_id = r.repertuar_id
LEFT JOIN bilety_seans bt ON bt.repertuar_id = r.repertuar_id
GROUP BY
  f.film_id,
  f.tytul,
  TRUNC(r.data_rozpoczecia, 'IW');

