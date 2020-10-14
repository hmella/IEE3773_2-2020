clear; clc; close all

% Agrega funciones en src/ al path de matlab
addpath(genpath('src/'))


%% LECTURA DE IMAGEN DICOM
% Imagen de CSPAMM en dirección X
metadata = ReadPhilipsDICOM('data/IM_0001',{'MAGNITUDE','REAL','IMAGINARY'});
info = metadata.DICOMInfo;  % información del DICOM
R = metadata.REAL;          % imágenes de la parte real
I = metadata.IMAGINARY;     % imágenes de la parte imaginaria
I1 = R + 1j*I;              % imagen compleja

% Imagen de CSPAMM en dirección Y
metadata = ReadPhilipsDICOM('data/IM_0002',{'MAGNITUDE','REAL','IMAGINARY'});
info = metadata.DICOMInfo;  % información del DICOM
R = metadata.REAL;          % imágenes de la parte real
I = metadata.IMAGINARY;     % imágenes de la parte imaginaria
I2 = R + 1j*I;              % imagen compleja

% Tamaño de la imagen y número de frames
Isz = size(I1,[1 2]);
Nfr = size(I1,3);

% Muestra las imágenes
figure,
subplot 221
imagesc(abs(I1(:,:,1)))
subplot 222
imagesc(abs(itok(I1(:,:,1))))
subplot 223
imagesc(abs(I2(:,:,1)))
subplot 224
imagesc(abs(itok(I2(:,:,1))))


%% ESTIMACIÓN DE LA FASE HARMÓNICA
% Tamaño del pixel [mm]
pxsz = info.PerFrameFunctionalGroupsSequence.Item_3.Private_2005_140f.Item_1.PixelSpacing;

% Espaciamiento de las lineas de tag [mm]
spac = info.SharedFunctionalGroupsSequence.Item_1.Private_2005_140e.Item_1.TagSpacingFirstDimension;

% Frecuencia de codificación
ke = 2*pi/spac;

% Crea un filtro pasabaandas para cada una de las dimensiones
c  = Isz(1)*((ke/(2*pi))*pxsz(1));
H1 = ButterworthFilter(Isz,[0 c],20,5);
H2 = H1';

% Obtiene las imágenes filtradas
If1 = ktoi(H1.*itok(I1));
If2 = ktoi(H2.*itok(I2));

% Muestra las imágenes
figure,
subplot 321
imagesc(abs(itok(If1(:,:,1))))
subplot 322
imagesc(abs(itok(If2(:,:,1))))
subplot 323
imagesc(abs(If1(:,:,1)))
subplot 324
imagesc(abs(If2(:,:,1)))
subplot 325
imagesc(angle(If1(:,:,1)))
subplot 326
imagesc(angle(If2(:,:,1)))
               

%% SEGEMENTACIÓN DEL VENTRICULO
% Fase armónica para la segmentación
phi = angle(permute(cat(4,If1,If2),[1 2 4 3]));

% Imagen para la segmentación
Is = abs(I1.*I2);
Is = Is./max(Is,[],[1 2]);

% Segmentación manual de los datos
segmentation = getSegmentation(struct('Image',Is,'Phase',phi,...
                  'Axis',[80 256 80 256],'Contours',contours));
