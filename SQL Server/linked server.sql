IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'kinolodz')
BEGIN
    EXEC master.dbo.sp_dropserver
         @server     = N'kinolodz',
         @droplogins = 'droplogins';
END
GO

sp_addlinkedserver
     @server =  N'kinolodz'
     ,  @srvproduct =  N''
     ,  @provider =  N'OraOLEDB.Oracle' 
     ,  @datasrc =  N'  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = SHARED)
      (SERVICE_NAME = pd19c)
    )
  )';
go

EXEC master.dbo.sp_serveroption 
  @server = N'kinolodz',
  @optname = N'rpc out',
  @optvalue = N'true';
GO


EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = N'kinolodz',
    @useself = 'false',
    @locallogin = N'adminKinoDB',
    @rmtuser = N'adminKinoDB',
    @rmtpassword = N'admin123';
GO


EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = N'kinolodz',
    @useself = 'false',
    @locallogin = N'userKinoDB',
    @rmtuser = N'userKinoDB',
    @rmtpassword = N'user123';


go
sp_addlinkedsrvlogin
    @rmtsrvname =  N'kinolodz'
     ,  @useself =  'false' 
     ,  @locallogin = NULL 
     ,  @rmtuser =  N'SCOTT' 
     ,  @rmtpassword =  N'12345' 
go