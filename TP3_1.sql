DROP TABLE IF EXISTS admins CASCADE;
DROP TABLE IF EXISTS posteTravail CASCADE;

DROP TYPE IF EXISTS Tadmin CASCADE;
DROP TYPE IF EXISTS TposteTravail CASCADE;

DROP SEQUENCE IF EXISTS numAdmin;
CREATE SEQUENCE numAdmin;

DROP SEQUENCE IF EXISTS numSerie;
CREATE SEQUENCE numSerie;

DROP SEQUENCE IF EXISTS numIP;
CREATE SEQUENCE numIP;

CREATE TYPE Tadmin AS (
    nadmin int,
    nom varchar(50),
    age int
);

CREATE TYPE TposteTravail AS (
    nSerie INT,
    adrIP VARCHAR(10),
    adminPC Tadmin
);


CREATE TABLE admins OF Tadmin (PRIMARY KEY (nadmin));
CREATE TABLE posteTravail OF TposteTravail (PRIMARY KEY (nserie));


INSERT INTO admins VALUES(nextval('numAdmin'), 'A1', 12);
INSERT INTO admins VALUES(nextval('numAdmin'), 'A2', 8);

INSERT INTO posteTravail VALUES
    (nextval('numSerie'), '193.54.227', NULL),
    (nextval('numSerie'), '102.54.254', NULL);

INSERT INTO posteTravail VALUES(nextval('numSerie'), '193.54.227',
    (select a from admins a where nom = 'A1'));

UPDATE posteTravail SET adminPC=(select a from admins a where nom = 'A2') WHERE nSerie=1;
UPDATE posteTravail SET adminPC=(select a from admins a where nom = 'A2') WHERE nSerie=2;

SELECT * FROM admins;
SELECT * FROM posteTravail;

UPDATE posteTravail SET adminPC=(select a from admins a where nom = 'A2') 
    WHERE adrIP='193.54.227';

UPDATE posteTravail p SET adminPC=null
    WHERE adrIP='193.54.227' and (p.adminPC).nom='A2';

DELETE FROM posteTravail WHERE adminPC IS NULL;

SELECT * FROM admins;
SELECT * FROM posteTravail;