-- Specyfikacja Pakietu admin_seanse
CREATE OR REPLACE PACKAGE admin_seanse AS

    -- Procedura dodaj¹ca nowy film
    PROCEDURE add_film(
        p_film_id       IN NUMBER,
        p_tytul         IN VARCHAR2,
        p_czas_trwania  IN NUMBER, -- w minutach
        p_minimalny_wiek IN NUMBER,
        p_kategoria_id  IN NUMBER
    );

    -- Procedura dodaj¹ca nowy seans
    PROCEDURE add_seans(
        p_repertuar_id     IN NUMBER,
        p_film_id          IN NUMBER,
        p_sala_id          IN NUMBER,
        p_data_rozpoczecia IN DATE
    );

    -- Definicja wyj¹tków
    EXCEPTION
        e_film_exists               WHEN OTHERS THEN;
        e_invalid_time_range         -- Jeœli czas seansu jest poza dozwolonym zakresem
            EXCEPTION;
        e_overlap_seans              -- Jeœli seans nachodzi na inny seans
            EXCEPTION;
        e_sala_not_found             -- Jeœli sala nie istnieje
            EXCEPTION;
        e_film_not_found             -- Jeœli film nie istnieje
            EXCEPTION;

END admin_seanse;
/
