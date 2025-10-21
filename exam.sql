DROP function IF EXISTS maj4;
DROP function IF EXISTS maj3;
DROP function IF EXISTS maj2;
DROP function IF EXISTS mises;
DROP TABLE IF EXISTS Vol;
DROP TABLE IF EXISTS Avion;
DROP TABLE IF EXISTS Pilote;
create table Avion(
    Avnum int Primary Key,
    typ Varchar(50)
);
create table Pilote(
    Pinum int Primary Key,
    Pinom Varchar(50),
    PiPrenom Varchar(50)
);
create table Vol(
    Volnum int Primary Key,
    Pinum int REFERENCES Pilote(Pinum),
    AVnum int REFERENCES Avion(Avnum),
    Heuredep TIME,
    HeureArr TIME);

INSERT INTO Avion VALUES(1,'a350');
INSERT INTO Avion VALUES(2,'a310');
INSERT INTO Pilote VALUES(1,'hugo','lelievre');
INSERT INTO Vol VALUES(2,1,1,'14:00','16:00');
INSERT INTO Vol VALUES(3,1,2,'14:00','16:00');
create function mises() returns void AS
$$
Declare
    c Cursor for Select * from Vol;
Begin
    for fly in c 
    LOOP
        UPDATE vol set HeureArr=fly.Heuredep+((fly.HeureArr-fly.Heuredep)*0.90) WHERE (Avnum=1)OR(Avnum=4);
        UPDATE vol set HeureArr=fly.Heuredep+((fly.HeureArr-fly.Heuredep)*0.85) WHERE (Avnum=2)OR(Avnum=8);
    END LOOP;
end;
 $$ LANGUAGE plpgsql;
 create function maj2(av int ,red float) returns void AS
$$
Declare
    c Cursor for Select * from Vol;
Begin
    for fly in c 
    LOOP
        UPDATE vol set HeureArr=fly.Heuredep+((fly.HeureArr-fly.Heuredep)*red) WHERE Avnum=av;
    END LOOP;
end;
 $$ LANGUAGE plpgsql;
create function maj3() returns void AS
$$
Declare
    c Cursor for Select * from Vol JOIN  Avion ON Vol.Avnum=Avion.Avnum WHERE (typ='a350') OR (typ='a310') for update of Vol ;
Begin
    for fly in c 
    LOOP
    if(fly.typ='a350') then
        UPDATE vol set HeureArr=fly.Heuredep+((fly.HeureArr-fly.Heuredep)*0.90) WHERE current of c;
    end if;
    if(fly.typ='a310') then 
        UPDATE vol set HeureArr=fly.Heuredep+((fly.HeureArr-fly.Heuredep)*0.85) WHERE current of c;
    END IF;
    END LOOP;
end;
 $$ LANGUAGE plpgsql;
create function maj3() returns void AS
$$
Declare
    c Cursor for Select * from Vol JOIN  Avion ON Vol.Avnum=Avion.Avnum WHERE (typ='a350') OR (typ='a310') for update of Vol ;
Begin
    for fly in c 
    LOOP
    if(fly.typ='a350') then
        UPDATE vol set HeureArr=fly.Heuredep+((fly.HeureArr-fly.Heuredep)*0.90) WHERE current of c;
    end if;
    if(fly.typ='a310') then 
        UPDATE vol set HeureArr=fly.Heuredep+((fly.HeureArr-fly.Heuredep)*0.85) WHERE current of c;
    END IF;
    END LOOP;
end;
 $$ LANGUAGE plpgsql;
 create function maj4(type2 VARCHAR(50),red float) returns void AS
$$
Declare
    c Cursor for Select * from Vol JOIN  Avion ON Vol.Avnum=Avion.Avnum WHERE (typ='a350') OR (typ='a310') for update of Vol ;
Begin
    for fly in c 
    LOOP
    if(fly.typ=type2) then
        UPDATE vol set HeureArr=fly.Heuredep+((fly.HeureArr-fly.Heuredep)*red) WHERE current of c;
    end if;
    END LOOP;
end;
 $$ LANGUAGE plpgsql;
 Select maj4('a350',0.30);
Select * from Vol JOIN  Avion ON Vol.Avnum=Avion.Avnum;
