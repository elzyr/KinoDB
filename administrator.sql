-- Specyfikacja Pakietu admin_seanse z dodan� procedur� popularnosc_filmu
CREATE OR REPLACE PACKAGE Admin_Pkg AS

    -- Istniej�ce procedury
    PROCEDURE dodaj_film(
        tytul_filmu          IN VARCHAR2,
        czas_trwania_filmu   IN NUMBER, -- w minutach
        wiek_minimalny IN NUMBER,
        id_kategorii   IN NUMBER
    );

    PROCEDURE dodaj_seans(
        id_filmu           IN NUMBER,
        id_sali           IN NUMBER,
        data_rozpoczecia_filmu  IN DATE
    );

    PROCEDURE dodaj_sale(
        nazwa_sali              IN VARCHAR2,
        ilosc_rzedow_w_sali       IN NUMBER,
        miejsca_w_rzedzie_sala  IN NUMBER
    );

    PROCEDURE dodaj_kategorie(
        nazwa_kategorii IN VARCHAR2
    );

    -- Nowa procedura do obliczania popularno�ci filmu
    PROCEDURE popularnosc_filmu(
        tytul_filmu IN VARCHAR2
    );

END Admin_Pkg;
/


-- Implementacja Pakietu admin_seanse
CREATE OR REPLACE PACKAGE BODY Admin_Pkg AS

    -- Procedura dodaj�ca nowy film
    PROCEDURE dodaj_film(
        tytul_filmu          IN VARCHAR2,
        czas_trwania_filmu   IN NUMBER,
        wiek_minimalny IN NUMBER,
        id_kategorii   IN NUMBER
    ) IS
        referencja_kategorii REF Kategoria;
    BEGIN
        -- Sprawdzenie czy kategoria istnieje
        SELECT REF(k)
        INTO referencja_kategorii
        FROM Kategoria_table k
        WHERE k.kategoria_id = id_kategorii;

        -- Wstawienie nowego filmu (id generowane automatycznie przez sekwencj�)
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
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'B��d podczas dodawania filmu. Upewnij si�, �e kategoria istnieje.');
    END dodaj_film;

    -- Procedura dodaj�ca nowy seans
    PROCEDURE dodaj_seans(
        id_filmu          IN NUMBER,
        id_sali          IN NUMBER,
        data_rozpoczecia_filmu IN DATE
    ) IS
        referencja_filmu         REF Film;
        referencja_sali         REF Sala;
        czas_trwania_filmu     NUMBER;
        data_zakonzcenia_filmu DATE;
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

        -- Obliczenie czasu zako�czenia seansu
        data_zakonzcenia_filmu := data_rozpoczecia_filmu + (czas_trwania_filmu + 30) / 1440;

        -- Sprawdzenie godzin rozpocz�cia i zako�czenia seansu
        IF TO_CHAR(data_rozpoczecia_filmu, 'HH24:MI') < '07:00' OR TO_CHAR(data_rozpoczecia_filmu, 'HH24:MI') > '22:00' THEN
            RAISE_APPLICATION_ERROR(-20002, 'Godzina rozpocz�cia seansu musi by� mi�dzy 07:00 a 22:00.');
        END IF;

        IF TO_CHAR(data_zakonzcenia_filmu, 'HH24:MI') > '23:59' THEN
            RAISE_APPLICATION_ERROR(-20002, 'Seans nie mo�e ko�czy� si� po p�nocy.');
        END IF;

        -- Sprawdzenie przerwy 30 minut mi�dzy seansami w tej samej sali
       SELECT COUNT(*)
        INTO czy_juz_jest_seans
        FROM Repertuar_table r
        WHERE r.sala_ref = referencja_sali
          AND (
                (data_rozpoczecia_filmu BETWEEN r.data_rozpoczecia AND (r.data_rozpoczecia + ((SELECT f.czas_trwania FROM Film_table f WHERE REF(f) = r.film_ref) + 30) / 1440))
                OR
                (data_zakonzcenia_filmu BETWEEN r.data_rozpoczecia AND (r.data_rozpoczecia + ((SELECT f.czas_trwania FROM Film_table f WHERE REF(f) = r.film_ref) + 30) / 1440))
                OR
                (r.data_rozpoczecia BETWEEN data_rozpoczecia_filmu AND data_zakonzcenia_filmu)
              );

        IF czy_juz_jest_seans > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Nowy seans koliduje z istniej�cymi seansami w tej sali.');
        END IF;

        -- Wstawienie nowego seansu (id generowane automatycznie przez sekwencj�)
        INSERT INTO Repertuar_table (
            film_ref,
            sala_ref,
            data_rozpoczecia
        ) VALUES (
            referencja_filmu,
            referencja_sali,
            data_rozpoczecia_filmu
        );
            DBMS_OUTPUT.PUT_LINE('przeszlo dodawanie');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20003, 'Seans koliduje z istniej�cymi seansami w tej sali.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'Nie znaleziono filmu lub sali.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20005, 'Nieznany b��d: ' || SQLERRM);

    END dodaj_seans;

    -- Procedura dodaj�ca now� sal�
    PROCEDURE dodaj_sale(
        nazwa_sali              IN VARCHAR2,
        ilosc_rzedow_w_sali       IN NUMBER,
        miejsca_w_rzedzie_sala  IN NUMBER
    ) IS
        miejsca_rezerwacja Miejsca_Typ := Miejsca_Typ();
        id_miejsca NUMBER := 1;
        dostepne_rzedy NUMBER;
        dostepne_miejsca NUMBER;
    BEGIN
        -- Tworzenie zagnie�d�onej tabeli miejsc
        FOR dostepne_rzedy IN 1..ilosc_rzedow_w_sali LOOP
            FOR dostepne_miejsca IN 1..miejsca_w_rzedzie_sala LOOP
                miejsca_rezerwacja.EXTEND;
                miejsca_rezerwacja(miejsca_rezerwacja.COUNT) := Miejsce(id_miejsca, dostepne_rzedy, dostepne_miejsca, 0);
                id_miejsca := id_miejsca + 1;
            END LOOP;
        END LOOP;

        -- Wstawienie nowej sali z miejscami
        INSERT INTO Sala_table (
            nazwa,
            miejsca
        ) VALUES (
            nazwa_sali,
            miejsca_rezerwacja
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20005, 'B��d podczas dodawania sali. Sprawd� dane wej�ciowe.');
    END dodaj_sale;

    -- Procedura dodaj�ca now� kategori�
    PROCEDURE dodaj_kategorie(
        nazwa_kategorii IN VARCHAR2
    ) IS
    BEGIN
        -- Wstawienie nowej kategorii
        INSERT INTO Kategoria_table (
            nazwa
        ) VALUES (
            nazwa_kategorii
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'B��d podczas dodawania kategorii. Sprawd� dane wej�ciowe.');
    END dodaj_kategorie;

    -- Procedura do obliczania popularno�ci filmu
    PROCEDURE popularnosc_filmu(
        tytul_filmu IN VARCHAR2
    ) IS
        id_filmu      NUMBER;
        referencja_filmu     REF Film;
        wszystkie_miejsca  NUMBER := 0;
        sprzedane_bilety NUMBER := 0;
        procent_sprzedazy   NUMBER;
    BEGIN
        -- Pobranie film_id na podstawie tytu�u
        SELECT film_id
        INTO id_filmu
        FROM Film_table
        WHERE tytul = tytul_filmu;

        -- Pobranie referencji do filmu
        SELECT REF(f)
        INTO referencja_filmu
        FROM Film_table f
        WHERE f.film_id = id_filmu;

        -- Obliczenie ca�kowitej liczby miejsc dost�pnych w ci�gu ostatnich 7 dni
        SELECT NVL(COUNT(*), 0)
        INTO wszystkie_miejsca
        FROM Repertuar_table r
        JOIN Sala_table s ON r.sala_ref = REF(s)
        CROSS JOIN TABLE(s.miejsca) m
        WHERE r.film_ref = referencja_filmu
          AND r.data_rozpoczecia >= SYSDATE - 7;

        -- Obliczenie liczby sprzedanych bilet�w w ci�gu ostatnich 7 dni
        SELECT NVL(COUNT(*), 0)
        INTO sprzedane_bilety
        FROM Bilet_table b
        WHERE b.seans_ref IN (
            SELECT REF(r_inner)
            FROM Repertuar_table r_inner
            WHERE r_inner.film_ref = referencja_filmu
              AND r_inner.data_rozpoczecia >= SYSDATE - 7
        );

        -- Obliczenie procentowego zape�nienia miejsc
        IF wszystkie_miejsca > 0 THEN
            procent_sprzedazy := (sprzedane_bilety / wszystkie_miejsca) * 100;
        ELSE
            procent_sprzedazy := 0;
        END IF;

        -- Wy�wietlenie wyniku
    DBMS_OUTPUT.PUT_LINE(
        'Popularno�� filmu "' || tytul_filmu || '" w ci�gu ostatnich 7 dni: ' || ROUND(procent_sprzedazy, 2) || '%'
    );


    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Nie znaleziono filmu o nazwie "' || tytul_filmu || '".');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Wyst�pi� b��d: ' || SQLERRM);
    END popularnosc_filmu;

END Admin_Pkg;
/
