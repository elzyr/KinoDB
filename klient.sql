SET SERVEROUTPUT ON;
CREATE OR REPLACE PACKAGE Klient_Pkg AS

    PROCEDURE Zarezerwuj_Seans(
        email_uzytkownika VARCHAR2,
        tytul_filmu VARCHAR2,
        data_seansu_in DATE,
        preferencja_rzedu NUMBER,
        ilosc_miejsc_do_zarezerwowania NUMBER
    );
  
    PROCEDURE Anuluj_Rezerwacje(
        tytul_filmu VARCHAR2,
        data_seansu_in DATE,
        email_uzytkownika VARCHAR2
    );
    
    PROCEDURE Pokaz_Rezerwacje(
        email_uzytkownika VARCHAR2
    );
    
    PROCEDURE Pokaz_Seanse(
        data_seansu_in DATE
    );
    
    PROCEDURE Zmien_Typ_Konta(
        email_uzytkownika VARCHAR2,
        nowy_typ_konta VARCHAR2
    );
    
    PROCEDURE Sprawdz_Wiek(
        email_uzytkownika VARCHAR2,
        tytul_filmu VARCHAR2
);

END Klient_Pkg;
/





CREATE OR REPLACE PACKAGE BODY Klient_Pkg AS

    PROCEDURE Sprawdz_Wiek(
        email_uzytkownika VARCHAR2,
        tytul_filmu VARCHAR2
    ) IS
        wiek_uzytkownika NUMBER;
        wymagany_wiek_filmu NUMBER;
    BEGIN
        -- Pobranie wieku uzytkownika
        SELECT u.wiek
        INTO wiek_uzytkownika
        FROM Uzytkownik_table u
        WHERE u.email = email_uzytkownika;
        
        -- Pobranie minimalnego wieku po tytule filmu
        SELECT MIN(f.minimalny_wiek) 
        INTO wymagany_wiek_filmu
        FROM Film_table f 
        WHERE f.tytul = tytul_filmu;
        
        -- Sprawdzenie wieku
        IF wiek_uzytkownika < wymagany_wiek_filmu THEN
            RAISE_APPLICATION_ERROR(-20008, 'Użytkownik nie spełnia wymaganego wieku dla tego filmu.');
        END IF;
    END Sprawdz_Wiek;

    PROCEDURE Zarezerwuj_Seans(
        email_uzytkownika VARCHAR2,
        tytul_filmu VARCHAR2,
        data_seansu_in DATE,
        preferencja_rzedu NUMBER,
        ilosc_miejsc_do_zarezerwowania NUMBER
    ) IS
        cena_laczna_rezerwacji NUMBER := 0;
        id_rezerwacji NUMBER;
        id_sali NUMBER;
        id_seansu NUMBER;
        referencja_uzytkownika REF Uzytkownik;
        miejsce_do_zarezerwowania NUMBER;
        rabat_uzytkownika NUMBER := 1.0;
        typ_konta_uzytkownika VARCHAR2(20);
    BEGIN
        -- Wywolanie procedury sprawdzajacej wiek
        BEGIN
            Sprawdz_Wiek(email_uzytkownika, tytul_filmu);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Użytkownik nie spełnia minimalnego wieku by pójść na film.');
                RETURN;
        END;

        -- Sprawdzenie czy uzytkownik kwalifikuje sie na rabat
        SELECT rola INTO typ_konta_uzytkownika FROM Uzytkownik_table WHERE email = email_uzytkownika;
        IF typ_konta_uzytkownika = 'premium' THEN
            rabat_uzytkownika := 0.9; 
        END IF;
        
        -- Pobieranie id_repertuaru
        SELECT r.repertuar_id
        INTO id_seansu
        FROM Repertuar_table r
        JOIN Film_table f ON REF(f) = r.film_ref
        WHERE f.tytul = tytul_filmu
        AND r.data_rozpoczecia = data_seansu_in;
        
        -- Pobierz sale danego repertuaru
        SELECT r.sala_ref.sala_id
        INTO id_sali
        FROM Repertuar_table r
        WHERE r.repertuar_id = id_seansu;
        
        SELECT REF(u)
        INTO referencja_uzytkownika
        FROM Uzytkownik_table u
        WHERE u.email = email_uzytkownika;
        
        -- Tworzenie rezerwacji
        cena_laczna_rezerwacji := ilosc_miejsc_do_zarezerwowania * 50 * rabat_uzytkownika;
        
        INSERT INTO Rezerwacja_table (rezerwacja_id, data_rezerwacji, cena_laczna, czy_anulowane, repertuar_ref, uzytkownik_ref, bilety)
        VALUES (
            rezerwacja_seq.NEXTVAL, SYSDATE, cena_laczna_rezerwacji, 0,
            (SELECT REF(r) FROM Repertuar_table r WHERE r.repertuar_id = id_seansu),
            referencja_uzytkownika,
            Bilety_Typ()
        )
        RETURNING rezerwacja_id INTO id_rezerwacji;
        
        -- Tworzenie biletow i aktualizacja statusu miejsc
        FOR i IN 1 .. ilosc_miejsc_do_zarezerwowania LOOP
            SELECT MIN(m.numer)
            INTO miejsce_do_zarezerwowania
            FROM TABLE(
                SELECT s.miejsca FROM Sala_table s WHERE s.sala_id = id_sali
            ) m
            WHERE m.rzad = preferencja_rzedu AND m.czy_zajete = 0;
            
            IF miejsce_do_zarezerwowania IS NULL THEN
                RAISE_APPLICATION_ERROR(-20007, 'Brak dostępnych miejsc w wybranym rzędzie.');
            END IF;
            
            -- Dodawanie biletu
            INSERT INTO Bilet_table (bilet_id, cena, seans_ref, rzad, miejsce)
            VALUES (
                bilet_seq.NEXTVAL, 25,
                (SELECT REF(r) FROM Repertuar_table r WHERE r.repertuar_id = id_seansu),
                preferencja_rzedu, miejsce_do_zarezerwowania
            );
            
            -- Zmiana statusu na zajęte dla miejsca
            UPDATE TABLE (
                SELECT s.miejsca FROM Sala_table s
                WHERE s.sala_id = id_sali
            ) m
            SET m.czy_zajete = 1
            WHERE m.rzad = preferencja_rzedu AND m.numer = miejsce_do_zarezerwowania
            AND EXISTS (
                SELECT 1 FROM Repertuar_table r
                WHERE r.repertuar_id = id_seansu
                AND r.sala_ref.sala_id = id_sali
            );
        END LOOP;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004, 'Nie znaleziono filmu lub sali.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20005, 'Nieznany błąd: ' || SQLERRM);
    END Zarezerwuj_Seans;

    PROCEDURE Anuluj_Rezerwacje(
        tytul_filmu VARCHAR2,
        data_seansu_in DATE,
        email_uzytkownika VARCHAR2
    ) IS
        id_seansu NUMBER;
        referencja_uzytkownika REF Uzytkownik;
        id_sali NUMBER;
        id_rezerwacji NUMBER;
    BEGIN
        -- Pobierz repertuar_id i id_sali
        SELECT r.repertuar_id, r.sala_ref.sala_id
        INTO id_seansu, id_sali
        FROM Repertuar_table r
        JOIN Film_table f ON REF(f) = r.film_ref
        WHERE f.tytul = tytul_filmu
        AND r.data_rozpoczecia = data_seansu_in;
    
        IF data_seansu_in - INTERVAL '1' HOUR < SYSDATE THEN
            DBMS_OUTPUT.PUT_LINE('Nie można anulować rezerwacji na mniej niż godzinę przed seansem.');
            RETURN;
        END IF;
    
        SELECT REF(u)
        INTO referencja_uzytkownika
        FROM Uzytkownik_table u
        WHERE u.email = email_uzytkownika;
    
        -- Pobierz id_rezerwacji użytkownika
        SELECT r.rezerwacja_id
        INTO id_rezerwacji
        FROM Rezerwacja_table r
        WHERE r.uzytkownik_ref = referencja_uzytkownika
        AND r.repertuar_ref = (SELECT REF(r) FROM Repertuar_table r WHERE r.repertuar_id = id_seansu)
        AND r.czy_anulowane = 0;
    
        -- Anulowanie rezerwacji dla użytkownika
        DBMS_OUTPUT.PUT_LINE('Rezerwacja anulowana. Zwolnienie miejsc obsłuży wyzwalacz.');
        UPDATE Rezerwacja_table
        SET czy_anulowane = 1
        WHERE rezerwacja_id = id_rezerwacji;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
    END Anuluj_Rezerwacje;

    PROCEDURE Pokaz_Rezerwacje(
        email_uzytkownika VARCHAR2
    ) IS
        referencja_uzytkownika REF Uzytkownik;
        ilosc_rezerwacji NUMBER := 0;
    BEGIN
        SELECT REF(u)
        INTO referencja_uzytkownika
        FROM Uzytkownik_table u
        WHERE u.email = email_uzytkownika;
        
        -- Sprawdzenie czy użytkownik ma rezerwacje
        SELECT COUNT(*)
        INTO ilosc_rezerwacji
        FROM Rezerwacja_table r
        WHERE r.uzytkownik_ref = referencja_uzytkownika;
    
        IF ilosc_rezerwacji = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Brak rezerwacji dla użytkownika ' || email_uzytkownika);
            RETURN;
        END IF;
        
        FOR r IN (
            SELECT r.rezerwacja_id, f.tytul, rep.data_rozpoczecia, TO_CHAR(rep.data_rozpoczecia, 'HH24:MI') AS godzina_seansu
            , r.cena_laczna, r.czy_anulowane
            FROM Rezerwacja_table r
            JOIN Repertuar_table rep ON REF(rep) = r.repertuar_ref
            JOIN Film_table f ON REF(f) = rep.film_ref
            WHERE r.uzytkownik_ref = referencja_uzytkownika
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('Rezerwacja ID: ' || r.rezerwacja_id || ' | Film: ' || r.tytul || ' | Data: ' || r.data_rozpoczecia  || 
                             ' | Godzina: ' || r.godzina_seansu || ' | Cena: ' || r.cena_laczna || ' | Anulowana: ' || r.czy_anulowane);
        END LOOP;
    END Pokaz_Rezerwacje;

    PROCEDURE Pokaz_Seanse(
        data_seansu_in DATE
    ) IS
    BEGIN
        FOR r IN (
            SELECT f.tytul, 
                   rep.data_rozpoczecia, 
                   TO_CHAR(rep.data_rozpoczecia, 'HH24:MI') AS godzina_seansu,
                   (SELECT COUNT(*) FROM TABLE(
                       SELECT s.miejsca FROM Sala_table s 
                       WHERE s.sala_id = rep.sala_ref.sala_id
                   ) WHERE czy_zajete = 0) AS dostepne_miejsca
            FROM Repertuar_table rep
            JOIN Film_table f ON REF(f) = rep.film_ref
            WHERE TRUNC(rep.data_rozpoczecia) = TRUNC(data_seansu_in)
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('Film: ' || r.tytul || 
                                 ' | Data: ' || TO_CHAR(r.data_rozpoczecia, 'YYYY-MM-DD') || 
                                 ' | Godzina: ' || r.godzina_seansu || 
                                 ' | Dostępne miejsca: ' || r.dostepne_miejsca);
        END LOOP;
    END Pokaz_Seanse;

    PROCEDURE Zmien_Typ_Konta(
        email_uzytkownika VARCHAR2,
        nowy_typ_konta VARCHAR2
    ) IS
        czy_uzytkownik_istnieje NUMBER := 0;
    BEGIN
        SELECT COUNT(*) INTO czy_uzytkownik_istnieje FROM Uzytkownik_table WHERE email = email_uzytkownika;
        IF czy_uzytkownik_istnieje = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Użytkownik o podanym emailu nie istnieje.');
            RETURN;
        END IF;
        
        IF nowy_typ_konta NOT IN ('standard', 'premium') THEN
            DBMS_OUTPUT.PUT_LINE('Niepoprawny typ konta. Dozwolone wartości: standard, premium.');
            RETURN;
        END IF;
        
        UPDATE Uzytkownik_table
        SET rola = nowy_typ_konta
        WHERE email = email_uzytkownika;
        DBMS_OUTPUT.PUT_LINE('Typ konta użytkownika ' || email_uzytkownika || ' został zmieniony na ' || nowy_typ_konta);
    END Zmien_Typ_Konta;

END Klient_Pkg;
/



