use KinoDB;
go

CREATE OR ALTER PROCEDURE dbo.ZarezerwujSeans
  @UserId          INT,
  @TytulFilmu      NVARCHAR(200),
  @DataSeansu      DATETIME,
  @PreferencjaRzad INT,
  @IloscMiejsc     INT,
  @KinoID          INT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @srv   SYSNAME,
    @rabat DECIMAL(3,2),
    @pl    NVARCHAR(MAX),
    @sql   NVARCHAR(MAX);

  SELECT 
    @srv   = k.Nazwa,
    @rabat = CASE WHEN u.rola = 'premium' THEN 0.9 ELSE 1.0 END
  FROM dbo.Kina k
  JOIN dbo.Uzytkownicy u
    ON u.user_id = @UserId
  WHERE k.kino_id = @KinoID;

  IF @srv IS NULL
    THROW 50000, 'Nieprawidlowe id kina', 1;

  SET @pl = 
    'BEGIN Klient_Pkg.Zarezerwuj_Seans('
    + CONVERT(VARCHAR(10), @UserId) + ','''
    + REPLACE(@TytulFilmu,'''','''''') + ''','''
    + CONVERT(CHAR(19), @DataSeansu, 120) + ''','
    + CONVERT(VARCHAR(10), @PreferencjaRzad) + ','
    + CONVERT(VARCHAR(10), @IloscMiejsc) + ','
    + CONVERT(VARCHAR(4), @rabat) + '); COMMIT; END;';

  SET @sql = 
    'EXEC(''' + REPLACE(@pl,'''','''''') + ''') AT ' + QUOTENAME(@srv);

  EXEC(@sql);
END;
GO

CREATE OR ALTER PROCEDURE dbo.AnulujRezerwacje
  @UserId     INT,
  @TytulFilmu NVARCHAR(200),
  @DataSeansu DATETIME,
  @KinoID     INT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @srv SYSNAME,
    @pl  NVARCHAR(MAX),
    @sql NVARCHAR(MAX);

  SELECT @srv = Nazwa
    FROM dbo.Kina
   WHERE kino_id = @KinoID;

  IF @srv IS NULL
    THROW 50001, 'Nieprawidlowe id kina', 1;

  SET @pl = 
    'BEGIN Klient_Pkg.Anuluj_Rezerwacje('
    + CONVERT(VARCHAR(10), @UserId) + ','''
    + REPLACE(@TytulFilmu,'''','''''') + ''','''
    + CONVERT(CHAR(19), @DataSeansu, 120) + '''); COMMIT; END;';

  SET @sql = 
    'EXEC(''' + REPLACE(@pl,'''','''''') + ''') AT ' + QUOTENAME(@srv);

  EXEC(@sql);
END;
GO

CREATE OR ALTER VIEW dbo.v_rezerwacje AS
SELECT *
FROM OPENQUERY(kinolodz,
  'SELECT 
     rezerwacja_id,
     tytul,
     data_seansu,
     rzad,
     miejsce,
     cena_laczna,
     uzytkownik
   FROM SCOTT.v_rezerwacje'
);
GO