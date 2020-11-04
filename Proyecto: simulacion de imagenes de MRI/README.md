# Proyecto: simulación de imágenes de MR
## Generación del fantoma
El fantoma a utilizar es similar al de la Experiencia 2, pero en este caso también consideraremos las inhomogeneidades de campo a través de la variable de off-resonance ```df```. Para su generación, puede considerar el siguiente script:
```matlab
% Dominio de la imagen
Isz = [100 100];
[X, Y] = meshgrid(linspace(-1,1,Isz(2)),linspace(-1,1,Isz(1)));
P = cat(3,X,Y);

% Centros de los cilindros
xc = [-0.5, 0.5; 0.5, 0.5; -0.5, -0.5; 0.5, -0.5];

% Crea el objeto con los cilindros
C = false([size(X), 4]);
for i=1:size(xc,1)
    C(:,:,i) = sqrt((X-xc(i,1)).^2 + (Y-xc(i,2)).^2) < 0.25;
end

% Valores T1 y T2 en cada cilindro
T1 = 4000*ones(Isz);
T2 = 1000*ones(Isz);
T12 = [1000 1500 850 500 4000; 200 300 50 20 1000];
for i=1:4
    T1(C(:,:,i)) = T12(1,i);
    T2(C(:,:,i)) = T12(2,i);
end

% Off-resonance
off = [0 100 200 300];
df = zeros(Isz);
for i=1:4
    df(C(:,:,i)) = off(i);
end
```

## Simple-MRI: una librería para simular la evolución de la magnetización
Como punto de partida del proyecto, utilizaremos la librería ```src/simple-MRI```, cuya implementación busca simular la evolución de la magnetización de forma matricial e iterativa (de forma similar a lo descrito por *Brian A. Hargreaves* en su página [Bloch Equation Simulation](http://mrsrl.stanford.edu/~brian/bloch/)).

La librería está compuesta por distintas funciones y clases de Matlab que les permitirá ver cómo se comporta la magnetización de un objeto frente a distintas combinaciones de pulsos de RF y gradientes. Por ejemplo, el siguiente código muestra cómo simular una secuencia de *Inversion-Recovery* utilizando ```simple-MRI```:
```matlab
% Constante giromagnetica
gamma = 42.58;   % MHz/T

%% Preparacion
% Pulso de inversion
RF_inv = RF(struct('angle',deg2rad(180.0),'phase',0,'ref_obj','ref'));

% Objeto 'Preparation'
prep = Preparation(struct('RF1',RF_inv));

%% Adquisición
% Pulso de excitacion
RF_ex = RF(struct('angle',deg2rad(15),'phase',deg2rad(0),'ref_obj','ref'));
crusher = GR(struct('dir',1,'ref_obj',RF_ex,'crusher',true));

% Objeto 'Acquisition'
acq = Acquisition(struct('RF1',RF_ex,'GR1',crusher,'prep_delay',325,'TR',100,'nb_frames',10));

% Objeto 'Sequence'
seq = Sequence(struct('preparation',prep,'acquisition',acq));

% Simulacion de la evolucion de la magnetizacion
api = struct(...
  'homogenize_times',      false,...
  'gyromagnetic_constant', gamma,...
  'M0',                    1.0,...
  'T1',                    T1,...
  'T2',                    T2,...
  'object',                C,...
  'image_coordinates',     P,...
  'off_resonance',         []);
metadata = Scan(seq,api);
Mxy = metadata.Mxy;
Mz = metadata.Mz;
```

El resultado del ejemplo anterior, obtenido con el fantoma descrito anteriormente, se muestra en la siguiente figura (cada curva representa la magnetización de cada uno de los cilindros):

<img src="https://github.com/hmella/IEE3773/blob/master/images/P1.png?raw=true" width="950" height="416">

## Hints
Para realizar su proyecto, usted deberá:
- Implementar los gradientes de codificación de fase y frecuencia (puede empezar por revisar la funcion [```src/simple-MRI/Scan.m```](https://github.com/hmella/IEE3773/blob/master/Proyecto:%20simulacion%20de%20imagenes%20de%20MRI/src/simple-MRI/src/Scan.m)).
- Implementar una función que les permita conocer la posición de cada punto del espacio k y su respectiva medición (vea la descripción de ```kx``` y ```ky``` en el enunciadod el proyecto).
