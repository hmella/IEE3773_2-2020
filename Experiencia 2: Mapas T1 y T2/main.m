clear; clc; close all

% Agrega funciones en src/ al path de matlab
addpath(genpath('src/'))


%% Generación del fantoma
% Dominio de la imagen
[X, Y] = meshgrid(linspace(-1,1,Isz(2)),linspace(-1,1,Isz(1)));

% Centros de los cilindros
C = [-0.5, 0.5; 0.5, 0.5; -0.5, -0.5; 0.5, -0.5];

% Crea el objeto con los cilindros
C = false([size(X), 4]);
for i=1:size(C,1)
    C(:,:,i) = sqrt((X-C(1,i)).^2 + (Y-C(2,i)).^2) < 0.25;
end

% Valores T1 y T2 en cada cilindro
t1 = [1000 1500 850 500];
t2 = [200 300 50 20];
T1 = t1(1)*C(:,:,1) + t1(2)*C(:,:,2) + ...
     t1(3)*C(:,:,3) + t1(4)*C(:,:,4);
T2 = t2(1)*C(:,:,1) + t2(2)*C(:,:,2) + ...
     t2(3)*C(:,:,3) + t2(4)*C(:,:,4);
T1(~(sum(C,3))) = 1e+10;
T2(~(sum(C,3))) = 1e+10;

% Verificación
figure,
subplot 121
imagesc(T1)
subplot 122
imagesc(T2)


%% Imágenes Look-Locker
% Lee raw data de una secuencia Look-Locker
K = squeeze(readListData('data/RAW/raw_000.list'));
K = K(1:2:end,:,:,:);   % corrige sobremuestreo

% Tamaño de la imagen, cantidad de bobinas y frames
Isz = size(K,[1 2]);
Nfr = size(K,3);
Ncoils = size(K,4);

% Del espacio K a la imagen (versión ruidosa)
I_noisy = ktoi(K, [1 2]);

% Remueve las altas frecuencias del espacio K y reconstruye una imagen
% suavizada
Wr = WindowFilter(Isz(1), 0.6, 0.3, 'Tukey');      % filtro en dimension de lectura
Wc = WindowFilter(Isz(2), 0.6, 0.3, 'Tukey');      % filtro en dimension de fase
I = ktoi((Wr.weights'*Wc.weights).*K, [1 2]);    % múltiples bobinas

figure,
tiledlayout(2,6,'Padding','compact','TileSpacing','compact')
coil=2;
for fr=1:Nfr
    nexttile
    imagesc(abs(I_noisy(:,:,fr,coil))); axis off; colormap gray,
end

figure,
tiledlayout(2,6,'Padding','compact','TileSpacing','compact')
coil=2;
for fr=1:Nfr
    nexttile
    imagesc(abs(I(:,:,fr,coil))); axis off; colormap gray
end

% A partir de un punto elegido por el usuario grafica la variación de 
% la señal a través del tiempo
figure,
imagesc(abs(I(:,:,1,coil)))
[cols,rows] = getpts(gca);
close(gcf)

figure,
for i=1:numel(cols)
    plot(21:66:Nfr*66,squeeze(real(I(round(rows(i)),round(cols(i)),:,coil))),'LineWidth',2); hold on
end
hold off

% Lectura de un DICOM de la adquisición Look-Locker
metadata = ReadPhilipsDICOM('data/DICOM/IM_000.dcm',{'MAGNITUDE','PHASE'});
info = metadata.DICOMInfo;  % información del DICOM
M = metadata.MAGNITUDE;     % imágenes de magnitud
P = metadata.PHASE;         % imágenes de fase

figure,
tiledlayout(2,6,'Padding','compact','TileSpacing','compact')
for fr=1:Nfr
    nexttile
    imagesc(M(:,:,fr)); axis off; colormap gray
end


%% Imágenes Multi-echo
% Lee raw data de una secuencia Multi-echo
K = squeeze(readListData('data/RAW/raw_002.list'));
K = K(1:2:end,:,:,:);   % corrige sobremuestreo

% Tamaño de la imagen, cantidad de bobinas y frames
Isz = size(K,[1 2]);
Nfr = size(K,3);
Ncoils = size(K,4);

% Del espacio K a la imagen
I = ktoi(K, [1 2]);
Itmp = I;
I(:,1:Isz(2)/2,:,:) = Itmp(:,Isz(2)/2+1:end,:,:);
I(:,Isz(2)/2+1:end,:,:) = Itmp(:,1:Isz(2)/2,:,:);

figure,
tiledlayout(2,4,'Padding','compact','TileSpacing','compact')
coil=2;
for fr=1:Nfr
    nexttile
    imagesc(abs(I(:,:,fr,coil))); axis off; colormap gray
    title(sprintf('TE = %d ms',TE(fr)))
end

% Lectura de un DICOM de la adquisición Multi-echo
metadata = ReadPhilipsDICOM('data/DICOM/IM_002.dcm',{'MAGNITUDE','PHASE'});
info = metadata.DICOMInfo;  % información del DICOM
M = metadata.MAGNITUDE;     % imágenes de magnitud
P = metadata.PHASE;         % imágenes de fase

figure,
tiledlayout(2,4,'Padding','compact','TileSpacing','compact')
for fr=1:Nfr
    nexttile
    imagesc(M(:,:,fr)); axis off; colormap gray
end