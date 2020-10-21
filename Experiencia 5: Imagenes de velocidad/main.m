%% CARGA DE LOS DATOS
% Lee raw data
load('data/labels.mat')
load('data/raw_all_c_real.mat')
load('data/raw_all_c_imag.mat')
raw_all_c = raw_all_c_real + 1j*raw_all_c_imag;

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


%% ORDENAMIENTO DE LOS DATOS
% Raw data
K = zeros(kx,ky,Nfr,Ns,Nc);

% Numero de datos adquiridos por segmento
Ndata = size(lab,1)/Ns;

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

%%
figure,
tiledlayout(2,4,'TileSpacing','compact','Padding','compact')
nexttile
imagesc(abs(I(:,:,5,1,4))); axis off
nexttile
imagesc(abs(I(:,:,5,2,4))); axis off
nexttile
imagesc(abs(I(:,:,5,3,4))); axis off
nexttile
imagesc(abs(I(:,:,5,4,4))); axis off
nexttile
imagesc(angle(I(:,:,5,1,4))); axis off
nexttile
imagesc(angle(I(:,:,5,2,4))); axis off
nexttile
imagesc(angle(I(:,:,5,3,4))); axis off
nexttile
imagesc(angle(I(:,:,5,4,4))); axis off
colormap gray