USE master;
GO
IF DB_ID(N'KinoDB') IS NOT NULL
BEGIN
    ALTER DATABASE KinoDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE KinoDB;
END
GO

CREATE DATABASE KinoDB;
GO

USE KinoDB;
GO


CREATE TABLE Kategorie (
    kategoria_id INT IDENTITY(1,1) PRIMARY KEY,
    nazwa NVARCHAR(100) NOT NULL
      CONSTRAINT UQ_Kategorie_nazwa UNIQUE(nazwa)
);
GO

CREATE TABLE Filmy (
    film_id INT IDENTITY(1,1) PRIMARY KEY,
    Tytul NVARCHAR(200) NOT NULL,
    minimalny_wiek INT NOT NULL
      CONSTRAINT CK_Filmy_minimalny_wiek CHECK (minimalny_wiek BETWEEN 0 AND 18),
    Czas_trwania INT NOT NULL
      CONSTRAINT CK_Filmy_czas_trwania CHECK (Czas_trwania > 0),
    kategoria_id INT NOT NULL
      CONSTRAINT FK_Filmy_Kategorie FOREIGN KEY (kategoria_id)
        REFERENCES dbo.Kategorie(kategoria_id),
    czy_wycofany BIT NOT NULL DEFAULT(0)
      CONSTRAINT CK_Filmy_czy_wycofany CHECK (czy_wycofany IN (0,1))
);
GO

CREATE TABLE Kina (
    kino_id INT IDENTITY(1,1) PRIMARY KEY,
    Nazwa SYSNAME NOT NULL
);
GO

CREATE TABLE statystyki_sprzedazy (
    stat_id INT IDENTITY(1,1) PRIMARY KEY,
    tytul NVARCHAR(200) NOT NULL,
    srednia_popularnosc DECIMAL(5,2) NOT NULL,
    poziom_oceny NVARCHAR(50) NOT NULL,
    ostatnia_aktualizacja DATETIME NOT NULL DEFAULT GETDATE()
);
GO


CREATE TABLE Uzytkownicy (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    Imie NVARCHAR(50) NOT NULL,
    Nazwisko NVARCHAR(50) NOT NULL,
    data_urodzenia DATE NOT NULL,
    Email NVARCHAR(100) NOT NULL
      CONSTRAINT UQ_Uzytkownicy_email UNIQUE(Email),
    rola NVARCHAR(20) NOT NULL
      CONSTRAINT CK_Uzytkownicy_rola CHECK (rola IN ('standard','premium'))
);
GO
