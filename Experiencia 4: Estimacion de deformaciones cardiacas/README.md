# Experiencia 4: Estimación de deformaciones cardiacas a partir de imágenes de tagging

## Imágenes disponibles
Para esta experiencia se encuentra disponible sólo un set de datos DICOM del eje corto de un ventriculo izquierdo adquirido en un voluntario sano. La adquisicón consiste de 2 imágenes de CSPAMM con lineas de tag perpendiculares entre si.
Para leer los datos utilice:
```matlab
% Imagen de CSPAMM en dirección X
metadata = ReadPhilipsDICOM('data/IM_0001',{'MAGNITUDE','REAL','IMAGINARY'});
R = metadata.REAL;          % imágenes de la parte real
I = metadata.IMAGINARY;     % imágenes de la parte imaginaria
I1 = R + 1j*I;              % imagen compleja

% Imagen de CSPAMM en dirección Y
metadata = ReadPhilipsDICOM('data/IM_0002',{'MAGNITUDE','REAL','IMAGINARY'});
R = metadata.REAL;          % imágenes de la parte real
I = metadata.IMAGINARY;     % imágenes de la parte imaginaria
I2 = R + 1j*I;              % imagen compleja
```

<img src="https://github.com/hmella/IEE3773/blob/master/images/Exp_4a.png?raw=true" width="950" height="225">



## Trabajando con las imágenes
Para obtener la fase armónica de las imágenes, se debe aplicar un filtro pasabandas centrado en la frecuencia de las líneas de tagging. Para obtener la información del espaciamiento de las líneas y el tamaño del pixel utilice:
```matlab
% Tamaño del pixel [mm]
pxsz = info.PerFrameFunctionalGroupsSequence.Item_3.Private_2005_140f.Item_1.PixelSpacing;

% Espaciamiento de las lineas de tag [mm]
spac = info.SharedFunctionalGroupsSequence.Item_1.Private_2005_140e.Item_1.TagSpacingFirstDimension;

% Frecuencia de codificación
ke = 2*pi/spac;
```

Para obtener los filtros pasabandas centrados en la frecuencia de las líneas de tag utilice:
```matlab
% Crea un filtro pasabaandas para cada una de las dimensiones
c  = Isz(1)*((ke/(2*pi))*pxsz(1));
H1 = ButterworthFilter(Isz,[0 c],20,5);
H2 = H1';

% Obtiene las imágenes filtradas
If1 = ktoi(H1.*itok(I1));
If2 = ktoi(H2.*itok(I2));
```

## Segmentación de los datos
En la carpeta ```src/``` se añadió una  ```gui``` de MATLAB para poder delinear y obtener una máscara del ventriculo izquierdo. Esto será útil para estimar las deformaciones y obtener información regional del movimiento del corazón.
Para utilizarla considere el siguiente script:
```matlab
% Fase armónica para la segmentación
phi = angle(permute(cat(4,If1,If2),[1 2 4 3]));

% Imagen para la segmentación
Is = abs(I1.*I2);
Is = Is./max(Is,[],[1 2]);

% Segmentación manual de los datos
segmentation = getSegmentation(struct('Image',Is,'Phase',phi,...
                  'Axis',[80 256 80 256]));
```
el cual abrirá una ventana en la cual podrá delinear los contornos del corazón.

<img src="https://github.com/hmella/IEE3773/blob/master/images/Exp_4c.png?raw=true" width="1050" height="600">

## Algunos tips e informaciones para el desarrollo de la experiencia
* Para la estimación de los gradientes de la fase armónica, puede utilizar la función ```src/unwrap2.m``` para corregir primero los artefactos de wrapping y después calcular los gradientes, o puede calcularlos directamente utilizando el operador gradiente propuesto en [Osman et al - 1999](https://github.com/hmella/IEE3773/blob/master/Experiencia%204:%20Estimacion%20de%20deformaciones%20cardiacas/bib/Osman%20et%20al.%20-%201999%20-%20Cardiac%20motion%20tracking%20using%20CINE%20harmonic%20phase%20(HARP)%20magnetic%20resonance%20imaging.pdf) (sin necesidad de corregir los artefactos).
* Para la obtención de las deformaciones regionales considere la función del siguiente [link](https://la.mathworks.com/matlabcentral/fileexchange/47454-bullseye-plot-zip).
* Recuerde que la fase armónica obtenida al filtrar las imágenes se encuentran en radianes, por lo que para obtener las posiciones del tejido deberá utilizar la frecuencia de codificación ```ke``` para obtener las posiciones en metros/milímetros/centímetros.
