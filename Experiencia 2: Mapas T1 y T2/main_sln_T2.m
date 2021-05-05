clear; clc; close all

% Agrega funciones en src/ al path de matlab
addpath(genpath('src/'))

% Lectura de un DICOM de la adquisición Look-Locker
metadata = ReadPhilipsDICOM('data/DICOM/IM_003.dcm',{'MAGNITUDE','PHASE','REAL','IMAGINARY'});
info = metadata.DICOMInfo;  % información del DICOM
M = metadata.MAGNITUDE;     % imágenes de magnitud

% Resize image
M = imresize3(M,[50 50 9]);

% Number of frames and image size
Nfr = size(M,3);
Isz = size(M,[1 2]);

figure,
tiledlayout(2,6,'Padding','compact','TileSpacing','compact')
for fr=1:Nfr
    nexttile
    imagesc(M(:,:,fr)); axis off; colormap gray
end

% Como la imagen adquirida con la bobina de cuerpo completo es muy ruidosa,
% la máscara del cerebro la obtendremos con las adquisiciones de cada
% bobina
mask = false(size(M,[1 2]));
for fr=1:Nfr
    mask = or(mask, abs(M(:,:,fr)) > 180);
end

% Elimina de la máscara aquellos pixeles que no están conectados
h = [0 1 0; 1 0 0; 0 0 0];
tmp = false(Isz(1:2));
for k = 1:4
    tmp(:,:,k) = conv2(double(mask),h,'same')==2;
    h = rot90(h);
end
mask = any(tmp,3) & mask;

figure,
imagesc(mask)


%% ESTIMACION DE MAPA T1
% Times of acqusisition of each frame
t = (20:20:20*Nfr)';

% Fitting options
fo = fitoptions('Method','NonlinearLeastSquares',...
               'Lower',[0,0,0],...
               'Upper',[2000,2500],...
               'StartPoint',[300 100]);
g = fittype('abs(b*exp(-x/c))','options',fo);


% Map estimation
T2 = NaN(Isz);

for i=1:Isz(1)
    for j=1:Isz(2)
        if mask(i,j)
            % Ajusta datos al modelo
            try
                f0 = fit(t,squeeze(M(i,j,:)),g);
                T2(i,j) = f0.c;
            catch
                1;
            end
        end
    end
    figure(1)
    imagesc(T2)
    caxis([0 500])
    colorbar
    drawnow    
end

%%
figure(1)
imagesc(T2)
caxis([0 150])
colorbar
drawnow
print('-dpng','-r150','T2')