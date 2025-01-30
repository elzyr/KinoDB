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
        -- Pobranie wieku u�ytkownika
        SELECT u.wiek INTO wiek_uzytkownika
        FROM Uzytkownik_table u
        WHERE u.email = email_uzytkownika;

        -- Pobranie minimalnego wieku dla filmu
        SELECT f.minimalny_wiek INTO wymagany_wiek_filmu
        FROM Film_table f
        WHERE f.tytul = tytul_filmu;

        -- Sprawdzenie wieku
        IF wiek_uzytkownika < wymagany_wiek_filmu THEN
            RAISE_APPLICATION_ERROR(-20008, 'U�ytkownik nie spe�nia wymaganego wieku dla tego filmu.');
        END IF;
    END Sprawdz_Wiek;

    PROCEDURE Zarezerwuj_Seans(
        email_uzytkownika VARCHAR2,
        tytul_filmu VARCHAR2,
        data_seansu_in DATE,
        preferencja_rzedu NUMBER,
        ilosc_miejsc_do_zarezerwowania NUMBER
    ) IS
        cena_laczna NUMBER := 0;
        id_rezerwacji NUMBER;
        id_sali NUMBER;
        id_seansu NUMBER;
        ref_uzytkownika REF Uzytkownik;
        ref_repertuar REF Repertuar; -- Dodana zmienna dla REF
        bilety_kolekcja Bilety_Typ := Bilety_Typ();
        rabat NUMBER := 1.0;
        typ_konta VARCHAR2(20);
    BEGIN
        -- Sprawdzenie wieku
        Sprawdz_Wiek(email_uzytkownika, tytul_filmu);

        -- Sprawdzenie rabatu
        BEGIN
            SELECT rola INTO typ_konta
            FROM Uzytkownik_table
            WHERE email = email_uzytkownika;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20009, 'U�ytkownik nie istnieje.');
        END;

        IF typ_konta = 'premium' THEN
            rabat := 0.9;
        END IF;

        -- Pobranie ID seansu i sali
        BEGIN
            SELECT r.repertuar_id, r.sala_ref.sala_id
            INTO id_seansu, id_sali
            FROM Repertuar_table r
            JOIN Film_table f ON REF(f) = r.film_ref
            WHERE f.tytul = tytul_filmu
            AND r.data_rozpoczecia = data_seansu_in;
            
            -- Pobierz REF do repertuaru
            SELECT REF(r) INTO ref_repertuar 
            FROM Repertuar_table r 
            WHERE r.repertuar_id = id_seansu;
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20010, 'Nie znaleziono seansu.');
        END;

        -- Rezerwacja miejsc
        FOR i IN 1..ilosc_miejsc_do_zarezerwowania LOOP
            DECLARE
                miejsce_rec Miejsce;
            BEGIN
                -- Znajd� wolne miejsce
                BEGIN
                    SELECT VALUE(m) INTO miejsce_rec
                    FROM TABLE(
                        SELECT s.miejsca FROM Sala_table s
                        WHERE s.sala_id = id_sali
                    ) m
                    WHERE m.rzad = preferencja_rzedu
                    AND m.czy_zajete = 0
                    AND ROWNUM = 1;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        RAISE_APPLICATION_ERROR(-20011, 'Brak wolnych miejsc w wybranym rz�dzie.');
                END;

                -- Dodaj bilet do kolekcji
                bilety_kolekcja.EXTEND;
                bilety_kolekcja(bilety_kolekcja.LAST) := Bilet(
                    bilet_seq.NEXTVAL,
                    25 * rabat,
                    ref_repertuar, -- U�yj zmiennej zamiast SELECT
                    preferencja_rzedu,
                    miejsce_rec.numer
                );

                -- Zaznacz miejsce jako zaj�te
                UPDATE TABLE(
                    SELECT s.miejsca FROM Sala_table s
                    WHERE s.sala_id = id_sali
                ) m
                SET m.czy_zajete = 1
                WHERE m.rzad = preferencja_rzedu
                AND m.numer = miejsce_rec.numer;
            END;
        END LOOP;

        -- Pobierz REF do u�ytkownika
        SELECT REF(u) INTO ref_uzytkownika
        FROM Uzytkownik_table u
        WHERE u.email = email_uzytkownika;

        -- Utw�rz rezerwacj�
        INSERT INTO Rezerwacja_table VALUES (
            rezerwacja_seq.NEXTVAL,
            SYSDATE,
            25 * ilosc_miejsc_do_zarezerwowania * rabat,
            0,
            ref_repertuar, -- U�yj zmiennej
            ref_uzytkownika, -- U�yj zmiennej
            bilety_kolekcja
        );

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20012, 'B��d rezerwacji: ' || SQLERRM);
    END Zarezerwuj_Seans;


    PROCEDURE Anuluj_Rezerwacje(
        tytul_filmu VARCHAR2,
        data_seansu_in DATE,
        email_uzytkownika VARCHAR2
    ) IS
        id_seansu NUMBER;
        id_rezerwacji NUMBER;
    BEGIN
        SELECT r.repertuar_id INTO id_seansu
        FROM Repertuar_table r
        JOIN Film_table f ON REF(f) = r.film_ref
        WHERE f.tytul = tytul_filmu
        AND r.data_rozpoczecia = data_seansu_in;

        IF SYSDATE > (SELECT data_rozpoczecia FROM Repertuar_table WHERE repertuar_id = id_seansu) - INTERVAL '1' HOUR THEN
            RAISE_APPLICATION_ERROR(-20006, 'Zbyt p�na anulacja!');
        END IF;

        SELECT rezerwacja_id INTO id_rezerwacji
        FROM Rezerwacja_table
        WHERE uzytkownik_ref = (SELECT REF(u) FROM Uzytkownik_table u WHERE u.email = email_uzytkownika)
        AND repertuar_ref = (SELECT REF(r) FROM Repertuar_table r WHERE r.repertuar_id = id_seansu)
        AND czy_anulowane = 0;

        UPDATE Rezerwacja_table
        SET czy_anulowane = 1
        WHERE rezerwacja_id = id_rezerwacji;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Brak aktywnych rezerwacji!');
    END Anuluj_Rezerwacje;

    PROCEDURE Pokaz_Rezerwacje(
        email_uzytkownika VARCHAR2
    ) IS
        CURSOR c_rezerwacje IS
            SELECT r.rezerwacja_id, f.tytul, r.data_rezerwacji, r.cena_laczna, r.bilety
            FROM Rezerwacja_table r
            JOIN Repertuar_table rep ON r.repertuar_ref = REF(rep)
            JOIN Film_table f ON rep.film_ref = REF(f)
            WHERE r.uzytkownik_ref = (SELECT REF(u) FROM Uzytkownik_table u WHERE u.email = email_uzytkownika);
    BEGIN
        FOR rezerwacja IN c_rezerwacje LOOP
            DBMS_OUTPUT.PUT_LINE('Rezerwacja ID: ' || rezerwacja.rezerwacja_id);
            DBMS_OUTPUT.PUT_LINE('Film: ' || rezerwacja.tytul);
            DBMS_OUTPUT.PUT_LINE('Data: ' || TO_CHAR(rezerwacja.data_rezerwacji, 'DD-MM-YYYY HH24:MI'));
            
            FOR bilet IN (SELECT * FROM TABLE(rezerwacja.bilety)) LOOP
                DBMS_OUTPUT.PUT_LINE('-> Miejsce: Rz�d ' || bilet.rzad || ', Numer ' || bilet.miejsce);
            END LOOP;
        END LOOP;
    END Pokaz_Rezerwacje;

    PROCEDURE Pokaz_Seanse(
        data_seansu_in DATE
    ) IS
    BEGIN
        FOR seans IN (
            SELECT f.tytul, r.data_rozpoczecia, 
                   (SELECT COUNT(*) FROM TABLE(s.miejsca) WHERE czy_zajete = 0) AS wolne_miejsca
            FROM Repertuar_table r
            JOIN Film_table f ON REF(f) = r.film_ref
            JOIN Sala_table s ON REF(s) = r.sala_ref
            WHERE TRUNC(r.data_rozpoczecia) = TRUNC(data_seansu_in)
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(seans.tytul || ' | ' || 
                TO_CHAR(seans.data_rozpoczecia, 'HH24:MI') || ' | Wolne miejsca: ' || seans.wolne_miejsca);
        END LOOP;
    END Pokaz_Seanse;

    PROCEDURE Zmien_Typ_Konta(
        email_uzytkownika VARCHAR2,
        nowy_typ_konta VARCHAR2
    ) IS
    BEGIN
        IF nowy_typ_konta NOT IN ('standard', 'premium') THEN
            RAISE_APPLICATION_ERROR(-20007, 'Niepoprawny typ konta!');
        END IF;

        UPDATE Uzytkownik_table
        SET rola = nowy_typ_konta
        WHERE email = email_uzytkownika;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20008, 'U�ytkownik nie istnieje!');
        END IF;
    END Zmien_Typ_Konta;

END Klient_Pkg;
/