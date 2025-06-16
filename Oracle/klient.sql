CREATE OR REPLACE PACKAGE Klient_Pkg AS

  PROCEDURE Zarezerwuj_Seans (
      p_user_id NUMBER,
      p_tytul_filmu VARCHAR2,
      p_data_seansu_in DATE,
      p_preferencja_rzedu NUMBER,
      p_ilosc_miejsc_do_zarezerwowania NUMBER,
      p_rabat NUMBER DEFAULT 1   -- 0.9 jesli premium
  );

  PROCEDURE Anuluj_Rezerwacje (
      p_user_id NUMBER,
      p_tytul_filmu VARCHAR2,
      p_data_seansu_in DATE
  );

  PROCEDURE Pokaz_Rezerwacje (
      p_user_id NUMBER
  );

  PROCEDURE Pokaz_Seanse (
      p_data_seansu_in DATE
  );
END Klient_Pkg;
/


CREATE OR REPLACE PACKAGE BODY Klient_Pkg AS

    PROCEDURE Zarezerwuj_Seans (
        p_user_id                         NUMBER,
        p_tytul_filmu                     VARCHAR2,
        p_data_seansu_in                  DATE,
        p_preferencja_rzedu               NUMBER,
        p_ilosc_miejsc_do_zarezerwowania  NUMBER,
        p_rabat                           NUMBER
    ) IS
        id_sali        NUMBER;
        id_seansu      NUMBER;
        ref_repertuar  REF Repertuar;
    
        bilety_kolekcja  Bilety_Typ := Bilety_Typ();
        current_bilet_id NUMBER      := 0;
        cnt NUMBER;
    BEGIN
            SELECT COUNT(*) INTO cnt
        FROM Rezerwacja_table
        WHERE uzytkownik = p_user_id
          AND repertuar_ref = (
                SELECT REF(r)
                FROM Repertuar_table r
                JOIN Film_table f ON f.film_id = DEREF(r.film_ref).film_id
                WHERE f.tytul = p_tytul_filmu
                  AND r.data_rozpoczecia = p_data_seansu_in
             )
          AND czy_anulowane = 0;
        
        IF cnt > 0 THEN
            RAISE_APPLICATION_ERROR(-20020, 'U¿ytkownik ju¿ zarezerwowa³ ten seans.');
        END IF;
        
        SELECT r.repertuar_id,
               DEREF(r.sala_ref).sala_id,
               REF(r)
        INTO   id_seansu, id_sali, ref_repertuar
        FROM   Repertuar_table r
        JOIN   Film_table      f ON f.film_id = DEREF(r.film_ref).film_id
        WHERE  f.tytul          = p_tytul_filmu
          AND  r.data_rozpoczecia = p_data_seansu_in;
    
        FOR i IN 1 .. p_ilosc_miejsc_do_zarezerwowania LOOP
            DECLARE
                miejsce_rec Miejsce;
            BEGIN
                SELECT VALUE(m)
                INTO   miejsce_rec
                FROM   TABLE(
                          SELECT s.miejsca
                          FROM   Sala_table s
                          WHERE  s.sala_id = id_sali
                       ) m
                WHERE  m.rzad       = p_preferencja_rzedu
                  AND  m.czy_zajete = 0
                FETCH FIRST 1 ROWS ONLY;
    
                /* Dodaj bilet do kolekcji */
                current_bilet_id := current_bilet_id + 1;
                bilety_kolekcja.EXTEND;
                bilety_kolekcja(bilety_kolekcja.LAST) := Bilet(
                       current_bilet_id,
                       50 * p_rabat,              -- cena z rabatem
                       p_preferencja_rzedu,
                       miejsce_rec.numer );
    
                /* Oznacz miejsce jako zajete */
                UPDATE TABLE(
                         SELECT s.miejsca
                         FROM   Sala_table s
                         WHERE  s.sala_id = id_sali
                      ) m
                SET    m.czy_zajete = 1
                WHERE  m.rzad   = p_preferencja_rzedu
                  AND  m.numer = miejsce_rec.numer;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20011,
                       'Brak wolnych miejsc w wybranym rzêdzie.');
            END;
        END LOOP;
    
        /* 1C.  Zapisz rezerwacje */
        INSERT INTO Rezerwacja_table VALUES (
            rezerwacja_seq.NEXTVAL,
            SYSDATE,
            50 * p_ilosc_miejsc_do_zarezerwowania * p_rabat,
            0,                 -- czy_anulowane
            ref_repertuar,
            p_user_id,         -- <- zapisujemy samo ID u¿ytkownika
            bilety_kolekcja
        );
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010, 'Nie znaleziono seansu.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20012,
                'B³¹d rezerwacji: ' || SQLERRM);
    END Zarezerwuj_Seans;

    -- Procedura do anulowania rezerwacji
PROCEDURE Anuluj_Rezerwacje (
      p_user_id        NUMBER,
      p_tytul_filmu    VARCHAR2,
      p_data_seansu_in DATE
  ) IS
      id_seansu  NUMBER;
      id_rezerw  NUMBER;
      dt_start   DATE;
      v_bilety   Rezerwacja_table.bilety%TYPE;
      v_sala_id  NUMBER;
  BEGIN
      /* seans */
      SELECT r.repertuar_id,
             r.data_rozpoczecia
        INTO id_seansu, dt_start
        FROM Repertuar_table r
        JOIN Film_table      f
          ON f.film_id = DEREF(r.film_ref).film_id
       WHERE f.tytul           = p_tytul_filmu
         AND r.data_rozpoczecia = p_data_seansu_in;

      IF SYSDATE > dt_start - 1/24 THEN
          RAISE_APPLICATION_ERROR(-20006,
            'Nie mo¿na anulowaæ rezerwacji mniej ni¿ godzinê przed seansem!');
      END IF;

      /* rezerwacja */
      SELECT rezerwacja_id
        INTO id_rezerw
        FROM Rezerwacja_table
       WHERE uzytkownik    = p_user_id
         AND repertuar_ref = (
               SELECT REF(r)
                 FROM Repertuar_table r
                WHERE r.repertuar_id = id_seansu
             )
         AND czy_anulowane = 0;

      UPDATE Rezerwacja_table
         SET czy_anulowane = 1
       WHERE rezerwacja_id = id_rezerw;

      SELECT bilety
        INTO v_bilety
        FROM Rezerwacja_table
       WHERE rezerwacja_id = id_rezerw;

      SELECT DEREF(r.sala_ref).sala_id
        INTO v_sala_id
        FROM Repertuar_table r
       WHERE r.repertuar_id = id_seansu;

      FOR b IN (
        SELECT b.rzad, b.miejsce
          FROM TABLE(v_bilety) b
      ) LOOP
        UPDATE TABLE(
          SELECT s.miejsca
            FROM Sala_table s
           WHERE s.sala_id = v_sala_id
        ) m
        SET m.czy_zajete = 0
        WHERE m.rzad   = b.rzad
          AND m.numer = b.miejsce;
      END LOOP;

  EXCEPTION
      WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20001,
            'Brak aktywnych rezerwacji!');
  END Anuluj_Rezerwacje;
    

    -- Procedura do wyswietlania rezerwacji uzytkownika
    PROCEDURE Pokaz_Rezerwacje (
        p_user_id NUMBER
    ) IS
        CURSOR c_rez IS
            SELECT r.rezerwacja_id,
                   f.tytul,
                   rep.data_rozpoczecia AS data_seansu,
                   r.cena_laczna,
                   r.bilety
            FROM   Rezerwacja_table r
            JOIN   Repertuar_table rep ON r.repertuar_ref = REF(rep)
            JOIN   Film_table      f   ON rep.film_ref    = REF(f)
            WHERE  r.uzytkownik = p_user_id;
    BEGIN
        FOR rec IN c_rez LOOP
            DBMS_OUTPUT.PUT_LINE('Rezerwacja ID: ' || rec.rezerwacja_id);
            DBMS_OUTPUT.PUT_LINE('Film: '         || rec.tytul);
            DBMS_OUTPUT.PUT_LINE('Data seansu: '  ||
                 TO_CHAR(rec.data_seansu,'DD-MM-YYYY HH24:MI'));
    
            FOR b IN (SELECT * FROM TABLE(rec.bilety)) LOOP
                DBMS_OUTPUT.PUT_LINE('-> Miejsce: Rz¹d '||b.rzad||
                                     ', Numer '||b.miejsce);
            END LOOP;
    
            DBMS_OUTPUT.PUT_LINE('Cena ³¹czna: ' || rec.cena_laczna || ' PLN');
            DBMS_OUTPUT.PUT_LINE('-------------------------------------');
        END LOOP;
    END Pokaz_Rezerwacje;


    -- Procedura do wyswietlania seansow w okreslonym dniu
    PROCEDURE Pokaz_Seanse (
        p_data_seansu_in DATE
    ) IS
    BEGIN
        FOR s IN (
            SELECT  f.tytul,
                    r.data_rozpoczecia,
                    (SELECT COUNT(*)
                       FROM TABLE(sa.miejsca)
                       WHERE czy_zajete = 0) AS wolne
            FROM   Repertuar_table r
            JOIN   Film_table  f  ON f.film_id = DEREF(r.film_ref).film_id
            JOIN   Sala_table  sa ON sa.sala_id = DEREF(r.sala_ref).sala_id
            WHERE  TRUNC(r.data_rozpoczecia) = TRUNC(p_data_seansu_in)
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
               s.tytul || ' | ' ||
               TO_CHAR(s.data_rozpoczecia, 'HH24:MI') ||
               ' | Wolne miejsca: ' || s.wolne);
        END LOOP;
    END Pokaz_Seanse;
END Klient_Pkg;
/