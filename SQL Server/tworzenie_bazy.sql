USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'KinoDB')
BEGIN
    DROP DATABASE KinoDB;
END
GO

CREATE DATABASE KinoDB;
GO

USE KinoDB;
GO

CREATE TABLE dbo.Kategorie
(
    kategoria_id INT           IDENTITY(1,1) PRIMARY KEY,
    nazwa        NVARCHAR(100) NOT NULL
                  CONSTRAINT UQ_Kategorie_nazwa UNIQUE(nazwa)
);
GO

-- Filmy
CREATE TABLE dbo.Filmy
(
    film_id        INT           IDENTITY(1,1) PRIMARY KEY,
    Tytul          NVARCHAR(200) NOT NULL,
    minimalny_wiek INT           NOT NULL
                  CONSTRAINT CK_Filmy_minimalny_wiek CHECK (minimalny_wiek BETWEEN 0 AND 18),
    Czas_trwania   INT           NOT NULL
                  CONSTRAINT CK_Filmy_czas_trwania CHECK (Czas_trwania > 0),
    kategoria_id   INT           NOT NULL
                  CONSTRAINT FK_Filmy_Kategorie FOREIGN KEY (kategoria_id)
                      REFERENCES dbo.Kategorie(kategoria_id),
    czy_wycofany   BIT           NOT NULL DEFAULT(0)
                  CONSTRAINT CK_Filmy_czy_wycofany CHECK (czy_wycofany IN (0,1))
);
GO

CREATE TABLE dbo.Kina
(
    kino_id INT           IDENTITY(1,1) PRIMARY KEY,
    Nazwa SYSNAME NOT NULL
);
GO

CREATE TABLE dbo.statystyki_sprzedazy
(
    stat_id     INT       IDENTITY(1,1) PRIMARY KEY,
    kino_id     INT       NOT NULL
                  CONSTRAINT FK_Sprzedazy_Kina FOREIGN KEY (kino_id)
                      REFERENCES dbo.Kina(kino_id),
    film_id     INT       NOT NULL
                  CONSTRAINT FK_Sprzedazy_Film FOREIGN KEY (film_id)
                      REFERENCES dbo.Filmy(film_id),
    data_start  DATETIME  NOT NULL,
    data_koniec DATETIME  NOT NULL,
    popularnosc INT       NOT NULL DEFAULT(0)
                  CONSTRAINT CK_Sprzedazy_popularnosc CHECK (popularnosc >= 0)
);
GO

CREATE TABLE dbo.Uzytkownicy
(
    user_id       INT           IDENTITY(1,1) PRIMARY KEY,
    Imie          NVARCHAR(50)  NOT NULL,
    Nazwisko      NVARCHAR(50)  NOT NULL,
    data_urodzenia DATE         NOT NULL,
    Email         NVARCHAR(100) NOT NULL
                  CONSTRAINT UQ_Uzytkownicy_email UNIQUE(Email),
    rola          NVARCHAR(20)  NOT NULL
                  CONSTRAINT CK_Uzytkownicy_rola CHECK (rola IN ('standard','premium'))
);
GO