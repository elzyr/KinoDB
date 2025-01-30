-- Specyfikacja Pakietu admin_seanse z dodan� procedur� popularnosc_filmu
CREATE OR REPLACE PACKAGE Admin_Pkg AS

    -- Istniej�ce procedury
    PROCEDURE dodaj_film(
        p_tytul          IN VARCHAR2,
        p_czas_trwania   IN NUMBER, -- w minutach
        p_minimalny_wiek IN NUMBER,
        p_kategoria_id   IN NUMBER
    );

    PROCEDURE dodaj_seans(
        p_film_id           IN NUMBER,
        p_sala_id           IN NUMBER,
        p_data_rozpoczecia  IN DATE
    );

    PROCEDURE dodaj_sale(
        p_nazwa              IN VARCHAR2,
        p_ilosc_rzedow       IN NUMBER,
        p_miejsca_w_rzedzie  IN NUMBER
    );

    PROCEDURE dodaj_kategorie(
        p_nazwa IN VARCHAR2
    );

    -- Nowa procedura do obliczania popularno�ci filmu
    PROCEDURE popularnosc_filmu(
        p_tytul IN VARCHAR2
    );

END Admin_Pkg;
/


-- Implementacja Pakietu admin_seanse
CREATE OR REPLACE PACKAGE BODY Admin_Pkg AS

    -- Procedura dodaj�ca nowy film
    PROCEDURE dodaj_film(
        p_tytul          IN VARCHAR2,
        p_czas_trwania   IN NUMBER,
        p_minimalny_wiek IN NUMBER,
        p_kategoria_id   IN NUMBER
    ) IS
        v_kategoria_ref REF Kategoria;
    BEGIN
        -- Sprawdzenie czy kategoria istnieje
        SELECT REF(k)
        INTO v_kategoria_ref
        FROM Kategoria_table k
        WHERE k.kategoria_id = p_kategoria_id;

        -- Wstawienie nowego filmu (id generowane automatycznie przez sekwencj�)
        INSERT INTO Film_table (
            tytul,
            czas_trwania,
            minimalny_wiek,
            kategoria_ref
        ) VALUES (
            p_tytul,
            p_czas_trwania,
            p_minimalny_wiek,
            v_kategoria_ref
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'B��d podczas dodawania filmu. Upewnij si�, �e kategoria istnieje.');
    END dodaj_film;

    -- Procedura dodaj�ca nowy seans
    PROCEDURE dodaj_seans(
        p_film_id          IN NUMBER,
        p_sala_id          IN NUMBER,
        p_data_rozpoczecia IN DATE
    ) IS
        v_film_ref         REF Film;
        v_sala_ref         REF Sala;
        v_czas_trwania     NUMBER;
        v_data_zakonczenia DATE;
        v_existing_seans_count NUMBER;
    BEGIN
        -- Pobranie referencji do filmu
        SELECT REF(f)
        INTO v_film_ref
        FROM Film_table f
        WHERE f.film_id = p_film_id;

        -- Pobranie referencji do sali
        SELECT REF(s)
        INTO v_sala_ref
        FROM Sala_table s
        WHERE s.sala_id = p_sala_id;

        -- Pobranie czasu trwania filmu
        SELECT f.czas_trwania
        INTO v_czas_trwania
        FROM Film_table f
        WHERE f.film_id = p_film_id;

        -- Obliczenie czasu zako�czenia seansu
        v_data_zakonczenia := p_data_rozpoczecia + (v_czas_trwania + 30) / 1440;

        -- Sprawdzenie godzin rozpocz�cia i zako�czenia seansu
        IF TO_CHAR(p_data_rozpoczecia, 'HH24:MI') < '07:00' OR TO_CHAR(p_data_rozpoczecia, 'HH24:MI') > '22:00' THEN
            RAISE_APPLICATION_ERROR(-20002, 'Godzina rozpocz�cia seansu musi by� mi�dzy 07:00 a 22:00.');
        END IF;

        IF TO_CHAR(v_data_zakonczenia, 'HH24:MI') > '23:59' THEN
            RAISE_APPLICATION_ERROR(-20002, 'Seans nie mo�e ko�czy� si� po p�nocy.');
        END IF;

        -- Sprawdzenie przerwy 30 minut mi�dzy seansami w tej samej sali
       SELECT COUNT(*)
        INTO v_existing_seans_count
        FROM Repertuar_table r
        WHERE r.sala_ref = v_sala_ref
          AND (
                (p_data_rozpoczecia BETWEEN r.data_rozpoczecia AND (r.data_rozpoczecia + ((SELECT f.czas_trwania FROM Film_table f WHERE REF(f) = r.film_ref) + 30) / 1440))
                OR
                (v_data_zakonczenia BETWEEN r.data_rozpoczecia AND (r.data_rozpoczecia + ((SELECT f.czas_trwania FROM Film_table f WHERE REF(f) = r.film_ref) + 30) / 1440))
                OR
                (r.data_rozpoczecia BETWEEN p_data_rozpoczecia AND v_data_zakonczenia)
              );

        IF v_existing_seans_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Nowy seans koliduje z istniej�cymi seansami w tej sali.');
        END IF;

        -- Wstawienie nowego seansu (id generowane automatycznie przez sekwencj�)
        INSERT INTO Repertuar_table (
            film_ref,
            sala_ref,
            data_rozpoczecia
        ) VALUES (
            v_film_ref,
            v_sala_ref,
            p_data_rozpoczecia
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
        p_nazwa              IN VARCHAR2,
        p_ilosc_rzedow       IN NUMBER,
        p_miejsca_w_rzedzie  IN NUMBER
    ) IS
        v_miejsca Miejsca_Typ := Miejsca_Typ();
        v_miejsce_id NUMBER := 1;
        v_rzad NUMBER;
        v_miejsce NUMBER;
    BEGIN
        -- Tworzenie zagnie�d�onej tabeli miejsc
        FOR v_rzad IN 1..p_ilosc_rzedow LOOP
            FOR v_miejsce IN 1..p_miejsca_w_rzedzie LOOP
                v_miejsca.EXTEND;
                v_miejsca(v_miejsca.COUNT) := Miejsce(v_miejsce_id, v_rzad, v_miejsce, 0);
                v_miejsce_id := v_miejsce_id + 1;
            END LOOP;
        END LOOP;

        -- Wstawienie nowej sali z miejscami
        INSERT INTO Sala_table (
            nazwa,
            miejsca
        ) VALUES (
            p_nazwa,
            v_miejsca
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20005, 'B��d podczas dodawania sali. Sprawd� dane wej�ciowe.');
    END dodaj_sale;

    -- Procedura dodaj�ca now� kategori�
    PROCEDURE dodaj_kategorie(
        p_nazwa IN VARCHAR2
    ) IS
    BEGIN
        -- Wstawienie nowej kategorii
        INSERT INTO Kategoria_table (
            nazwa
        ) VALUES (
            p_nazwa
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'B��d podczas dodawania kategorii. Sprawd� dane wej�ciowe.');
    END dodaj_kategorie;

    -- Procedura do obliczania popularno�ci filmu
    PROCEDURE popularnosc_filmu(
        p_tytul IN VARCHAR2
    ) IS
        v_film_id      NUMBER;
        v_film_ref     REF Film;
        v_total_seats  NUMBER := 0;
        v_sold_tickets NUMBER := 0;
        v_percentage   NUMBER;
    BEGIN
        -- Pobranie film_id na podstawie tytu�u
        SELECT film_id
        INTO v_film_id
        FROM Film_table
        WHERE tytul = p_tytul;

        -- Pobranie referencji do filmu
        SELECT REF(f)
        INTO v_film_ref
        FROM Film_table f
        WHERE f.film_id = v_film_id;

        -- Obliczenie ca�kowitej liczby miejsc dost�pnych w ci�gu ostatnich 7 dni
        SELECT NVL(COUNT(*), 0)
        INTO v_total_seats
        FROM Repertuar_table r
        JOIN Sala_table s ON r.sala_ref = REF(s)
        CROSS JOIN TABLE(s.miejsca) m
        WHERE r.film_ref = v_film_ref
          AND r.data_rozpoczecia >= SYSDATE - 7;

        -- Obliczenie liczby sprzedanych bilet�w w ci�gu ostatnich 7 dni
        SELECT NVL(COUNT(*), 0)
        INTO v_sold_tickets
        FROM Bilet_table b
        WHERE b.seans_ref IN (
            SELECT REF(r_inner)
            FROM Repertuar_table r_inner
            WHERE r_inner.film_ref = v_film_ref
              AND r_inner.data_rozpoczecia >= SYSDATE - 7
        );

        -- Obliczenie procentowego zape�nienia miejsc
        IF v_total_seats > 0 THEN
            v_percentage := (v_sold_tickets / v_total_seats) * 100;
        ELSE
            v_percentage := 0;
        END IF;

        -- Wy�wietlenie wyniku
    DBMS_OUTPUT.PUT_LINE(
        'Popularno�� filmu "' || p_tytul || '" w ci�gu ostatnich 7 dni: ' || ROUND(v_percentage, 2) || '%'
    );


    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Nie znaleziono filmu o nazwie "' || p_tytul || '".');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Wyst�pi� b��d: ' || SQLERRM);
    END popularnosc_filmu;

END Admin_Pkg;
/
