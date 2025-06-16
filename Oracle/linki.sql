-- login na adminKinoDB
CREATE DATABASE LINK user_link
CONNECT TO userKinoDB IDENTIFIED BY user123
USING 'pd19c';

-- sys
CREATE PUBLIC DATABASE LINK kino_link
CONNECT TO userKinoDB IDENTIFIED BY user123
USING 'pd19c';


CREATE OR REPLACE PROCEDURE pokaz_seanse_zdalne IS
BEGIN
  FOR s IN (SELECT * FROM SCOTT.vw_seanse@kino_link)
  LOOP
    DBMS_OUTPUT.PUT_LINE(s.tytul || ' - ' || TO_CHAR(s.data_rozpoczecia, 'YYYY-MM-DD HH24:MI'));
  END LOOP;
END;

-- tetsowanie
-- U¿yæ kwalifikowanego odwo³ania:
SELECT * FROM scott.vw_seanse@kino_link;

