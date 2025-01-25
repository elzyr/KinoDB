-- Specyfikacja Pakietu admin_seanse
CREATE OR REPLACE PACKAGE admin_seanse AS

    -- Procedura dodaj¹ca nowy film
    PROCEDURE add_film(
        p_tytul         IN VARCHAR2,
        p_czas_trwania  IN NUMBER, -- w minutach
        p_minimalny_wiek IN NUMBER,
        p_kategoria_id  IN NUMBER
    );

    -- Procedura dodaj¹ca nowy seans
    PROCEDURE add_seans(
        p_film_id          IN NUMBER,
        p_sala_id          IN NUMBER,
        p_data_rozpoczecia IN DATE
    );

    -- Procedura dodaj¹ca now¹ salê
    PROCEDURE add_sala(
        p_nazwa           IN VARCHAR2,
        p_ilosc_rzedow    IN NUMBER,
        p_miejsca_w_rzedzie IN NUMBER
    );

    -- Procedura dodaj¹ca now¹ kategoriê
    PROCEDURE add_kategoria(
        p_nazwa           IN VARCHAR2
    );

END admin_seanse;
/

-- Implementacja Pakietu admin_seanse
CREATE OR REPLACE PACKAGE BODY admin_seanse AS

    -- Procedura dodaj¹ca nowy film
    PROCEDURE add_film(
        p_tytul         IN VARCHAR2,
        p_czas_trwania  IN NUMBER,
        p_minimalny_wiek IN NUMBER,
        p_kategoria_id  IN NUMBER
    ) IS
        v_kategoria_ref REF Kategoria;
    BEGIN
        -- Sprawdzenie czy kategoria istnieje
        SELECT REF(k)
        INTO v_kategoria_ref
        FROM Kategoria_table k
        WHERE k.kategoria_id = p_kategoria_id;

        -- Wstawienie nowego filmu (id generowane automatycznie przez sekwencjê)
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
            RAISE_APPLICATION_ERROR(-20001, 'B³¹d podczas dodawania filmu. Upewnij siê, ¿e kategoria istnieje.');
    END add_film;

    -- Procedura dodaj¹ca nowy seans
    PROCEDURE add_seans(
        p_film_id          IN NUMBER,
        p_sala_id          IN NUMBER,
        p_data_rozpoczecia IN DATE
    ) IS
        v_film_ref       REF Film;
        v_sala_ref       REF Sala;
        v_czas_trwania   NUMBER;
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

        -- Obliczenie czasu zakoñczenia seansu
        v_data_zakonczenia := p_data_rozpoczecia + NUMTODSINTERVAL(v_czas_trwania + 30, 'MINUTE');

        -- Sprawdzenie godzin rozpoczêcia i zakoñczenia seansu
        IF TO_CHAR(p_data_rozpoczecia, 'HH24:MI') < '07:00' OR TO_CHAR(p_data_rozpoczecia, 'HH24:MI') > '22:00' THEN
            RAISE_APPLICATION_ERROR(-20002, 'Godzina rozpoczêcia seansu musi byæ miêdzy 07:00 a 22:00.');
        END IF;

        IF TO_CHAR(v_data_zakonczenia, 'HH24:MI') > '23:59' THEN
            RAISE_APPLICATION_ERROR(-20002, 'Seans nie mo¿e koñczyæ siê po pó³nocy.');
        END IF;

        -- Sprawdzenie przerwy 30 minut miêdzy seansami w tej samej sali
        SELECT COUNT(*)
        INTO v_existing_seans_count
        FROM Repertuar_table r
        WHERE r.sala_ref = v_sala_ref
          AND (
                (p_data_rozpoczecia BETWEEN r.data_rozpoczecia AND (r.data_rozpoczecia + NUMTODSINTERVAL((SELECT f.czas_trwania FROM Film_table f WHERE REF(f) = r.film_ref) + 30, 'MINUTE')))
                OR
                (v_data_zakonczenia BETWEEN r.data_rozpoczecia AND (r.data_rozpoczecia + NUMTODSINTERVAL((SELECT f.czas_trwania FROM Film_table f WHERE REF(f) = r.film_ref) + 30, 'MINUTE')))
                OR
                (r.data_rozpoczecia BETWEEN p_data_rozpoczecia AND v_data_zakonczenia)
              );


        IF v_existing_seans_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Nowy seans koliduje z istniej¹cymi seansami w tej sali.');
        END IF;

        -- Wstawienie nowego seansu (id generowane automatycznie przez sekwencjê)
        INSERT INTO Repertuar_table (
            film_ref,
            sala_ref,
            data_rozpoczecia
        ) VALUES (
            v_film_ref,
            v_sala_ref,
            p_data_rozpoczecia
        );

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20004, 'B³¹d podczas dodawania seansu. SprawdŸ dane wejœciowe.');
    END add_seans;

    -- Procedura dodaj¹ca now¹ salê
    PROCEDURE add_sala(
        p_nazwa           IN VARCHAR2,
        p_ilosc_rzedow    IN NUMBER,
        p_miejsca_w_rzedzie IN NUMBER
    ) IS
        v_miejsca Miejsca_Typ := Miejsca_Typ();
        v_miejsce_id NUMBER := 1;
        v_rzad NUMBER;
        v_miejsce NUMBER;
    BEGIN
        -- Tworzenie zagnie¿d¿onej tabeli miejsc
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
            RAISE_APPLICATION_ERROR(-20005, 'B³¹d podczas dodawania sali. SprawdŸ dane wejœciowe.');
    END add_sala;

    -- Procedura dodaj¹ca now¹ kategoriê
    PROCEDURE add_kategoria(
        p_nazwa           IN VARCHAR2
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
            RAISE_APPLICATION_ERROR(-20006, 'B³¹d podczas dodawania kategorii. SprawdŸ dane wejœciowe.');
    END add_kategoria;

END admin_seanse;
