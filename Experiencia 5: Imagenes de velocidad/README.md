# Experiencia 5: Imágenes de velocidad

## Imágenes disponibles
Para esta experiencia se encuentra disponible sólo un set de datos de una aorta de un voluntario, contenido en los archivos ```labels.mat```, ```raw_all_c_real.mat``` y ```raw_all_c_imag.mat```.

Los datos consisten de 4 imágenes (segmentos) de *Phase-Contrast* (PC), las cuales fueron adquiridas sin codificación de velocidad (segmento 1) y con codificación de velocidad en tres  direcciones perpendiculares (segmento 2, 3 y 4), incluyendo la dirección a través del plano.

Para leer los datos utilice:
```matlab
% Lee las variables lab y raw_all_c
load('data/labels.mat')
load('data/raw_all_c_real.mat')
load('data/raw_all_c_imag.mat')
raw_all_c = raw_all_c_real + 1j*raw_all_c_imag;
```


## Re-ordenando los datos
Las variables ```lab``` y ```raw_all_c``` contienen toda la información necesaria para reconstruir las imágenes de velocidad. 
La variable ```raw``` contiene la información sobre cómo fueron adquiridos los datos:
* La primera y segunda columna corresponde a <img src="https://latex.codecogs.com/gif.latex?k_y" title="k_y" /> y <img src="https://latex.codecogs.com/gif.latex?k_z" title="k_z" />.
* La tercera columna contiene informaci\ón sobre el tiempo de cuando fue adquirida la línea del espacio <img src="https://latex.codecogs.com/gif.latex?k" title="k" /> en un ciclo cardiaco.
* La cuarta columna entrega informaci\ón de si los datos fueron adquiridos correctamente o rechazados por algún motivo (arritmia por ejemplo). Si el valor de esta columna es 0, los datos fueron correctamente adquiridos.
* La sexta fila entrega informaci\ón sobre la fase cardíaca.

Por otra parte, la variable ```raw``` contiene los datos de cada línea del espacio k organizados de acuerdo a los labels contenidos en ```lab```, de manera que:
* La primera dimensión contiene los puntos adquiridos en <img src="https://latex.codecogs.com/gif.latex?k_x" title="k_x" />.
* La última dimensión corresponde al número de bobinas.

De esta manera, las dimensiones del raw data se pueden obtener de la siguiente manera:

```matlab
% Numero de filas
kx = size(raw_all_c, 1);

% Numero de columnas
ky = max(lab(:,1)) + 1;

% Numero de fases cardiacas
Nfr = max(lab(:,end)) + 1;

% Numero de segmentos
Ns = 4;

% Numero de bobinas
Nc = size(raw_all_c, 3);
```

Para re-ordenar los datos, puede utilizar el siguiente código:
```matlab
% Raw data
K = zeros(kx,ky,Nfr,Ns,Nc);

% Numero de datos adquiridos por segmento
Ndata = size(lab,1)/n_ss;

% Re-ordenamiento de los datos
for k=1:Ndata
    K(:,lab(4*(k-1)+1,1)+1,lab(4*(k-1)+1,end)+1,1,:) = raw_all_c(:,4*(k-1)+1,:); 
    K(:,lab(4*(k-1)+2,1)+1,lab(4*(k-1)+2,end)+1,2,:) = raw_all_c(:,4*(k-1)+2,:); 
    K(:,lab(4*(k-1)+3,1)+1,lab(4*(k-1)+3,end)+1,3,:) = raw_all_c(:,4*(k-1)+3,:); 
    K(:,lab(4*(k-1)+4,1)+1,lab(4*(k-1)+4,end)+1,4,:) = raw_all_c(:,4*(k-1)+4,:); 
end

% Del espacio k al dominio de la imagen
I = ktoi(K(1:2:end,:,:,:,:), [1,2]);
I = circshift(I,ky/2,2);
```
Obteniendo las imágenes de abajo para la bobina 4 y todos los segmentos.
<img src="https://github.com/hmella/IEE3773_2-2020/blob/master/images/Exp_5a.png?raw=true" width="950" height="450">
