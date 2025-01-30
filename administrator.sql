CREATE OR REPLACE PACKAGE Admin_Pkg AS
    PROCEDURE dodaj_kategorie(
        nazwa_kategorii IN VARCHAR2
    );
    PROCEDURE dodaj_film(
        tytul_filmu IN VARCHAR2,
        czas_trwania_filmu IN NUMBER, -- w minutach
        wiek_minimalny IN NUMBER,
        id_kategorii IN NUMBER
    );
    PROCEDURE dodaj_sale(
        nazwa_sali IN VARCHAR2,
        ilosc_rzedow_w_sali IN NUMBER,
        miejsca_w_rzedzie_sala IN NUMBER
    );
    PROCEDURE dodaj_seans(
        id_filmu IN NUMBER,
        id_sali IN NUMBER,
        data_rozpoczecia_filmu IN DATE
    );
    PROCEDURE popularnosc_filmu(
        tytul_filmu IN VARCHAR2
    );

END Admin_Pkg;
/
CREATE OR REPLACE PACKAGE BODY Admin_Pkg AS

    PROCEDURE dodaj_film(
        tytul_filmu IN VARCHAR2,
        czas_trwania_filmu IN NUMBER,
        wiek_minimalny IN NUMBER,
        id_kategorii IN NUMBER
    ) IS
        referencja_kategorii REF Kategoria;
    BEGIN
        -- Sprawdzenie czy kategoria istnieje
        SELECT REF(k)
        INTO referencja_kategorii
        FROM Kategoria_table k
        WHERE k.kategoria_id = id_kategorii;

        INSERT INTO Film_table (
            tytul,
            czas_trwania,
            minimalny_wiek,
            kategoria_ref
        ) VALUES (
            tytul_filmu,
            czas_trwania_filmu,
            wiek_minimalny,
            referencja_kategorii
        );
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                RAISE_APPLICATION_ERROR(-20002, 'Film o podanym tytule juz istnieje.');
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20003, 'Podana kategoria nie istnieje.');
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20001, 'Wystapil blad podczas dodawania filmu');
    END dodaj_film;

    PROCEDURE dodaj_seans(
        id_filmu IN NUMBER,
        id_sali IN NUMBER,
        data_rozpoczecia_filmu IN DATE
    ) IS
        referencja_filmu REF Film;
        referencja_sali REF Sala;
        czas_trwania_filmu NUMBER;
        data_zakonczenia_filmu DATE;
        czy_juz_jest_seans NUMBER;
    BEGIN
        -- Pobranie referencji do filmu
        SELECT REF(f)
        INTO referencja_filmu
        FROM Film_table f
        WHERE f.film_id = id_filmu;

        -- Pobranie referencji do sali
        SELECT REF(s)
        INTO referencja_sali
        FROM Sala_table s
        WHERE s.sala_id = id_sali;

        -- Pobranie czasu trwania filmu
        SELECT f.czas_trwania
        INTO czas_trwania_filmu
        FROM Film_table f
        WHERE f.film_id = id_filmu;

        data_zakonczenia_filmu := data_rozpoczecia_filmu + (czas_trwania_filmu + 30) / 1440;

        IF TO_CHAR(data_rozpoczecia_filmu, 'HH24:MI') < '07:00' OR TO_CHAR(data_rozpoczecia_filmu, 'HH24:MI') > '22:00' THEN
            RAISE_APPLICATION_ERROR(-20004, 'Kino rozpoczyna nowe seanse w godzinach 7:00 - 22:00.');
        END IF;

        SELECT COUNT(*)
        INTO czy_juz_jest_seans
        FROM Repertuar_table r
        WHERE r.sala_ref = referencja_sali
          AND (
                (data_rozpoczecia_filmu BETWEEN r.data_rozpoczecia AND (r.data_rozpoczecia + ((SELECT f.czas_trwania FROM Film_table f WHERE REF(f) = r.film_ref) + 30) / 1440))
                OR
                (data_zakonczenia_filmu BETWEEN r.data_rozpoczecia AND (r.data_rozpoczecia + ((SELECT f.czas_trwania FROM Film_table f WHERE REF(f) = r.film_ref) + 30) / 1440))
                OR
                (r.data_rozpoczecia BETWEEN data_rozpoczecia_filmu AND data_zakonczenia_filmu)
              );

        IF czy_juz_jest_seans > 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Seans koliduje z istniejacymi seansami w tej sali.');
        END IF;

        INSERT INTO Repertuar_table (
            film_ref,
            sala_ref,
            data_rozpoczecia
        ) VALUES (
            referencja_filmu,
            referencja_sali,
            data_rozpoczecia_filmu
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20006, 'Nie znaleziono filmu lub sali.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20007, SQLERRM);
    END dodaj_seans;

    PROCEDURE dodaj_sale(
        nazwa_sali IN VARCHAR2,
        ilosc_rzedow_w_sali IN NUMBER,
        miejsca_w_rzedzie_sala IN NUMBER
    ) IS
        miejsca_rezerwacja Miejsca_Typ := Miejsca_Typ();
        id_miejsca NUMBER := 1;
        dostepne_rzedy NUMBER;
        dostepne_miejsca NUMBER;
    BEGIN
        FOR dostepne_rzedy IN 1..ilosc_rzedow_w_sali LOOP
            FOR dostepne_miejsca IN 1..miejsca_w_rzedzie_sala LOOP
                miejsca_rezerwacja.EXTEND;
                miejsca_rezerwacja(miejsca_rezerwacja.COUNT) := Miejsce(id_miejsca, dostepne_rzedy, dostepne_miejsca, 0);
                id_miejsca := id_miejsca + 1;
            END LOOP;
        END LOOP;

        INSERT INTO Sala_table (
            nazwa,
            miejsca
        ) VALUES (
            nazwa_sali,
            miejsca_rezerwacja
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20008, 'Sala o podanej nazwie juz istnieje.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20009, 'Wystapil blad podczas dodawania sali');
    END dodaj_sale;

    PROCEDURE dodaj_kategorie(
        nazwa_kategorii IN VARCHAR2
    ) IS
    BEGIN
        INSERT INTO Kategoria_table (nazwa) VALUES (nazwa_kategorii);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20010, 'Kategoria o podanej nazwie juz istnieje.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20011, 'Wystapil blad podczas dodawania kategorii: ' || SQLERRM);
    END dodaj_kategorie;

    PROCEDURE popularnosc_filmu(
        tytul_filmu IN VARCHAR2
    ) IS
        id_filmu NUMBER;
        referencja_filmu REF Film;
        wszystkie_miejsca NUMBER := 0;
        sprzedane_bilety NUMBER := 0;
        procent_sprzedazy NUMBER;
    BEGIN
        SELECT film_id
        INTO id_filmu
        FROM Film_table
        WHERE tytul = tytul_filmu;

        SELECT REF(f)
        INTO referencja_filmu
        FROM Film_table f
        WHERE f.film_id = id_filmu;

        SELECT NVL(COUNT(*), 0)
        INTO wszystkie_miejsca
        FROM Repertuar_table r
        JOIN Sala_table s ON r.sala_ref = REF(s)
        CROSS JOIN TABLE(s.miejsca) m
        WHERE r.film_ref = referencja_filmu
          AND r.data_rozpoczecia >= SYSDATE - 7;

        SELECT NVL(COUNT(*), 0)
        INTO sprzedane_bilety
        FROM Bilet_table b
        WHERE b.seans_ref IN (
            SELECT REF(r_inner)
            FROM Repertuar_table r_inner
            WHERE r_inner.film_ref = referencja_filmu
              AND r_inner.data_rozpoczecia >= SYSDATE - 7
        );

        IF wszystkie_miejsca > 0 THEN
            procent_sprzedazy := (sprzedane_bilety / wszystkie_miejsca) * 100;
        ELSE
            procent_sprzedazy := 0;
        END IF;

        DBMS_OUTPUT.PUT_LINE('Film "' || tytul_filmu || '" w ciagu ostatnich 7 dni byl zapelniony w: ' || ROUND(procent_sprzedazy, 2) || '%');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20012, 'Nie znaleziono filmu o nazwie "' || tytul_filmu || '".');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'Wystapil blad podczas obliczania popularnosci: ' || SQLERRM);
    END popularnosc_filmu;

END Admin_Pkg;
/
