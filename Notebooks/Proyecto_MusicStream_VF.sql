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

SELECT genero_musica, AVG(playcount) AS promedio_reproducciones
	FROM last_fm
	GROUP BY genero_musica -- Agrupación por género.
	ORDER BY promedio_reproducciones DESC -- Orden descendente para obtener el mayor promedio.
	LIMIT 1; -- Solo el género con el promedio más alto, queremos un solo resultado. 


-- 2. ¿Cuántos artistas pertenecen a cada género en la base de datos y cuál es el género con más artistas?

SELECT genero, COUNT(DISTINCT artista) AS cantidad_artistas -- Usamos distinct para asegurarnos de que cada artista lo contamos SOLO 1 vez por género. 
	FROM spotipy
	GROUP BY genero -- Agrupación por género.
	ORDER BY cantidad_artistas DESC; -- Orden descendente para obtener el género con más artistas.

-- 3. ¿Cuántos artistas tienen menos de 100,000 reproducciones?

SELECT COUNT(DISTINCT artista) AS artistas_menos_de_100k -- Aquí volvemos a usar DISTINCT para que no cuente las filas con más de 1 canción por género como un artista nuevo. 
	FROM last_fm
	WHERE playcount < 100000; -- Condición de menos de 100,000 reproducciones

-- 4. ¿Cuál es el artista con más Listeners?

SELECT artista, MAX(listeners) AS max_listeners -- Hacemos un máx, porque queremos saber el num.mayor. 
	FROM last_fm
	GROUP BY artista -- Agrupación por artista.
	ORDER BY max_listeners DESC -- Orden descendente para el mayor número de oyentes.
	LIMIT 1; -- Solo 1, el artista con más oyentes.

-- 5. ¿Qué país tiene mas artistas?

SELECT Pais_origen, COUNT(DISTINCT artista) AS cantidad_artistas
	FROM music_brainz
	GROUP BY Pais_origen -- Agrupación por país de origen.
	ORDER BY cantidad_artistas DESC
    LIMIT 1; -- Orden descendente para obtener el país con más artistas.

-- 6. ¿Qué artista estuvo más tiempo en activo y cuántas canciones tiene en el rango extraído de información (2022-2023)?

-- Hacemos una subconsulta derivada, que actuará como tabla temporal en el FROM de nuestra consulta princial, para calcular el tiempo activo solo para artistas activos 
-- Artistas activos =>(Fecha_fin_act = 'No Data'). Calculamos el tiempo de actividad hasta 31-12-23 puesto que no tenemos datos más alla de esa fecha*/

SELECT artista_info.Artista,
 FLOOR(artista_info.tiempo_activo), -- FLOOR para que nos devuelva años completos
 COUNT(s.nombre) AS cantidad_canciones  -- Contamos las canciones asociadas al artista.
FROM (
    SELECT 
        mb.Artista,
        DATEDIFF('2023-12-31', STR_TO_DATE(mb.Fecha_ini_act, '%Y-%m-%d')) / 365.0 AS tiempo_activo  -- Calcula tiempo activo hasta el 31-12-2023
    FROM 
        music_brainz AS mb
    WHERE mb.Fecha_fin_act = 'No Data'  -- Solo artistas en activo
        AND mb.Fecha_ini_act IS NOT NULL  -- Aseguramos que Fecha_ini_act tenga un valor
        AND mb.Fecha_ini_act != ''  -- Aseguramos que Fecha_ini_act no esté vacío
) AS artista_info
LEFT JOIN spotipy AS s ON artista_info.Artista = s.artista 
GROUP BY artista_info.Artista, artista_info.tiempo_activo
ORDER BY artista_info.tiempo_activo DESC 
LIMIT 1;  -- Obtenemos el artista con más tiempo activo hasta 31-12-2023


-- ---------------------------------------------------------------------------
-- BONUS (Identidad): 

-- 1. ¿Cuál es el porcentaje de listeners que escuhan a mujeres VS listeners que esuchan a hombres?  

SELECT 
    mb.Genero AS genero_artista,
    SUM(lf.listeners) AS total_listeners,
    ROUND(SUM(lf.listeners) * 100.0 / (SELECT SUM(listeners) FROM last_fm), 2) AS porcentaje_listeners
FROM 
    last_fm lf
INNER JOIN 
    music_brainz AS mb ON lf.artista = mb.Artista
WHERE 
    mb.Genero IN ('male', 'female')  -- Filtramos por géneros específicos
GROUP BY 
    mb.Genero;

-- 2. ¿Cuáles son las artistas mujeres más escuchadas?

SELECT lf.artista, SUM(playcount) AS total_reproducciones
	FROM last_fm as lf
INNER JOIN music_brainz as mb
         ON lf.artista = mb.Artista
WHERE mb.genero = 'female'
GROUP BY lf.artista
ORDER BY total_reproducciones DESC
LIMIT 10;

-- 3. ¿En qué género ha crecido más el número de reproducciones de artistas femeninas?

SELECT lf.genero_musica, SUM(playcount) AS total_reproducciones
FROM last_fm as lf
INNER JOIN music_brainz as mb
    ON lf.artista = mb.Artista
INNER JOIN SPOTIPY as s 
    ON lf.artista = s.artista
WHERE mb.genero = 'female'
GROUP BY lf.genero_musica
ORDER BY total_reproducciones DESC
LIMIT 1;