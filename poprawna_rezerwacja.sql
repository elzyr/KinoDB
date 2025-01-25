BEGIN
    -- Dodawanie kategorii
    admin_seanse.add_kategoria('Komedia');
    admin_seanse.add_film(
        p_tytul => 'Wielka Przygoda',
        p_czas_trwania => 120,
        p_minimalny_wiek => 7,
        p_kategoria_id => 1 -- ID kategorii 'Komedia'
    );
    
END;
/

begin
    admin_seanse.add_sala(
        p_nazwa => 'Sala 1',
        p_ilosc_rzedow => 5,
        p_miejsca_w_rzedzie => 10
    );
        -- Dodaj film
    admin_seanse.add_film(
        p_tytul => 'Film A',
        p_czas_trwania => 120,
        p_minimalny_wiek => 12,
        p_kategoria_id => 1 -- Zak³adaj¹c, ¿e istnieje kategoria o ID 1
    );

    -- Dodaj seans
    admin_seanse.add_seans(
        p_film_id => 1, -- Zak³adaj¹c, ¿e ID filmu to 1
        p_sala_id => 1, -- Zak³adaj¹c, ¿e ID sali to 1
        p_data_rozpoczecia => TO_DATE('2026-01-30 15:00', 'YYYY-MM-DD HH24:MI')
    );
end;
/


BEGIN
    INSERT INTO Uzytkownik_table VALUES (
        Uzytkownik(
            NULL,
            'Piotr',
            'Zieliñski',
            40,
            'piotr.zielinski@example.com',
            'standard'
        )
    );
END;
/

BEGIN
    Klient_Pkg.PokazSeanseNaDzien(TO_DATE('2026-01-30', 'YYYY-MM-DD'));
END;

BEGIN
    Klient_Pkg.ZarezerwujMiejsca(
        p_email => 'piotr.zielinski@example.com',
        p_film_tytul => 'Wielka Przygoda',
        p_ilosc => 5,
        p_data => TO_DATE('2026-01-30 15:00', 'YYYY-MM-DD HH24:MI'),
        p_preferencja_rzad => 1 
    );
END;
/

BEGIN
    Klient_Pkg.PokazRezerwacjeUzytkownika('piotr.zielinski@example.com');
END;
/