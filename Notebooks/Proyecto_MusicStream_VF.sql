-- Crear el esquema y usarlo
CREATE SCHEMA musicstream;
USE musicstream;

-- Tabla principal: SPOTIPY

CREATE TABLE SPOTIPY (
    artista VARCHAR(255) PRIMARY KEY, -- Nombre único del artista
    genero VARCHAR(255), -- Género musical del artista
    tipo VARCHAR(50), -- Tipo de publicación: 'canción' o 'álbum'
    nombre VARCHAR(255), -- Nombre de la canción o álbum
    año_lanzamiento YEAR, -- Año de lanzamiento
    cantidad_canciones INT -- Cantidad de canciones en el álbum o 1 si es una canción
);

-- Tabla secundaria 1: MUSIC_BRAINZ

CREATE TABLE MUSIC_BRAINZ (
    artista VARCHAR(255),
    genero VARCHAR(255), 
    pais_origen VARCHAR(255), -- País de origen del artista
    area_origen VARCHAR(255), -- Región de origen
    inicio_actividad DATETIME, -- Fecha de inicio de actividad del artista
    fin_actividad DATETIME, -- Fecha de fin de actividad (si aplica)
    identidad VARCHAR(255), -- Identidad de género del artista
    FOREIGN KEY (artista) REFERENCES SPOTIPY(artista) -- Conexión con tabla SPOTIPY
);

-- Tabla secundaria 2: LAST_FM

CREATE TABLE LAST_FM (
    artista VARCHAR(255),
    genero VARCHAR(255), 
    biografia TEXT, -- Biografía limitada a 5000 caracteres
    listeners INT, -- Total de oyentes del artista
    playcount INT, -- Total de reproducciones
    artistas_similares TEXT, -- Tres artistas similares
    FOREIGN KEY (artista) REFERENCES SPOTIPY(artista) -- Conexión con tabla SPOTIPY
);


-- 1. ¿Qué género tiene el promedio más alto de reproducciones?

SELECT genero, AVG(playcount) AS promedio_reproducciones
	FROM LAST_FM
	GROUP BY genero -- Agrupación por género.
	ORDER BY promedio_reproducciones DESC -- Orden descendente para obtener el mayor promedio.
	LIMIT 1; -- Solo el género con el promedio más alto, queremos un solo resultado. 


-- 2. ¿Cuántos artistas pertenecen a cada género en la base de datos y cuál es el género con más artistas?

SELECT genero, COUNT(DISTINCT artista) AS cantidad_artistas -- Usamos distinct para asegurarnos de que cada artista lo contamos SOLO 1 vez por género. 
	FROM SPOTIPY
	GROUP BY genero -- Agrupación por género.
	ORDER BY cantidad_artistas DESC; -- Orden descendente para obtener el género con más artistas.

-- 3. ¿Cuántos artistas tienen menos de 100,000 reproducciones?

SELECT COUNT(DISTINCT artista) AS artistas_menos_de_100k -- Aquí volvemos a usar DISTINCT para que no cuente las filas con más de 1 canción por género como un artista nuevo. 
	FROM LAST_FM
	WHERE playcount < 100000; -- Condición de menos de 100,000 reproducciones

-- 4. ¿Cuál es el artista con más Listeners?

SELECT artista, MAX(listeners) AS max_listeners -- Hacemos un máx, porque queremos saber el num.mayor. 
	FROM LAST_FM
	GROUP BY artista -- Agrupación por artista.
	ORDER BY max_listeners DESC -- Orden descendente para el mayor número de oyentes.
	LIMIT 1; -- Solo 1, el artista con más oyentes.

-- 5. ¿Qué país tiene mas artistas?

SELECT pais_origen, COUNT(DISTINCT artista) AS cantidad_artistas
	FROM MUSIC_BRAINZ
	GROUP BY pais_origen -- Agrupación por país de origen.
	ORDER BY cantidad_artistas DESC; -- Orden descendente para obtener el país con más artistas.

-- 6. ¿Qué artista estuvo más tiempo en activo y cuántas canciones tiene en el rango extraído de información (2022-2023)?

SELECT s.artista, 
       (YEAR(mb.fin_actividad) - YEAR(mb.inicio_actividad)) AS tiempo_activo, -- usamos el year para extraer solo el año (y no un datetime). 
       COUNT(s.nombre) AS cantidad_canciones -- Contamos las canciones o álbumes.
FROM SPOTIPY as s
INNER JOIN MUSIC_BRAINZ as mb 
ON s.artista = mb.artista -- Unimos las tablas SPOTIPY y MUSIC_BRAINZ por artista.
GROUP BY s.artista
ORDER BY tiempo_activo DESC -- Ordenar de mayor a menor tiempo activo.
LIMIT 1; -- Obtener solo el artista con más tiempo activo. 


-- ---------------------------------------------------------------------------
-- BONUS (Identidad): 

-- 1. ¿Cuál es el porcentaje de listeners que escuhan a mujeres VS listeners que esuchan a hombres?  

SELECT identidad, 
       (SUM(listeners) * 100.0 / (SELECT SUM(listeners) 
       FROM LAST_FM as lf
       INNER JOIN MUSIC_BRAINZ as mb
       ON lf.artista = mb.artista 
       WHERE identidad IN ('Mujer', 'Hombre'))) AS porcentaje_listeners
FROM LAST_FM as lf -- ¡¡¡¡Aquí tengo dudas si lo tengo que diferenciar del anterior!!!
INNER JOIN MUSIC_BRAINZ as mb
ON lf.artista = mb.artista
WHERE identidad IN ('Mujer', 'Hombre')
GROUP BY identidad;

-- 2. ¿Cuáles son las artistas mujeres más escuchadas?

SELECT artista, SUM(playcount) AS total_reproducciones
	FROM LAST_FM as lf
	INNER JOIN MUSIC_BRAINZ as mb
    ON lf.artista = mb.artista
	WHERE identidad = 'Mujer'
	GROUP BY artista
	ORDER BY total_reproducciones DESC
	LIMIT 10;

-- 3. ¿En qué género ha crecido más el número de reproducciones de artistas femeninas?

SELECT genero, SUM(playcount) AS total_reproducciones
	FROM LAST_FM as lf
	INNER JOIN MUSIC_BRAINZ as mb
    ON lf.artista = mb.artista
INNER JOIN SPOTIPY as s
ON lf.artista = s.artista
WHERE identidad = 'Mujer'
GROUP BY genero
ORDER BY total_reproducciones DESC
LIMIT 1;

