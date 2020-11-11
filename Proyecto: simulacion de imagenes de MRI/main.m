clear; clc; close all

% Agrega funciones en src/ al path de matlab
addpath(genpath('src/'))


% Gyromagnetic constant
gamma = 42.58;   % MHz/T


%% Generación del fantoma
% Dominio de la imagen
Isz = [64 64];
[X, Y] = meshgrid(linspace(-1,1,Isz(2)),linspace(-1,1,Isz(1)));
P = 0.15*cat(3,X,Y); % field of view = [0.3, 0.3] metros

% Centros y radios de los cilindros
xc = [0 0; -0.25, 0.25; 0.25, 0.25; -0.25, -0.25; 0.25, -0.25];
r  = [0.75 0.2 0.2 0.2 0.2];

% Crea el objeto con los cilindros
C = false([size(X), 4]);
for i=1:numel(r)
    C(:,:,i) = sqrt((X-xc(i,1)).^2 + (Y-xc(i,2)).^2) < r(i);
end

% Valores T1 y T2 en cada cilindro
T1 = zeros(Isz);
T2 = zeros(Isz);
T12 = [4000 1000 1500 850 500 250;
       1000 200  300  50  20  75];
for i=1:numel(r)
    T1(C(:,:,i)) = T12(1,i);
    T2(C(:,:,i)) = T12(2,i);
end

% Off-resonance
off = [0 5 10 15 20];
df = zeros(Isz);
for i=1:numel(r)
    df(C(:,:,i)) = off(i);
end

% Verificación
figure,
subplot 131
imagesc(T1); set(gca,'YDir','normal'); caxis([0 4000])
axis off
subplot 132
imagesc(T2); set(gca,'YDir','normal'); caxis([0 1000])
axis off
subplot 133
imagesc(df); set(gca,'YDir','normal'); caxis([0 20])
axis off


%% Obtención de Mxy
% Pulso de inversion
RF_inv = RF(struct('angle',deg2rad(180.0),'phase',0,'ref_obj','ref'));

% Objeto 'Preparation'
prep = Preparation(struct('RF1',RF_inv));

% Pulso de excitacion
RF_ex = RF(struct('angle',deg2rad(15),'phase',deg2rad(0),'ref_obj','ref'));
crusher = GR(struct('dir',1,'ref_obj',RF_ex,'crusher',true));

% Objecto 'Acquisition'
acq = Acquisition(struct('RF1',RF_ex,'GR1',crusher,'prep_delay',325,'TR',100,'nb_frames',10));

% Objeto 'Sequence'
seq = Sequence(struct('preparation',prep,'acquisition',acq));

% Evolucion de la magnetizacion
api = struct(...
  'homogenize_times',      false,...
  'gyromagnetic_constant', gamma,...
  'M0',                    1.0,...
  'T1',                    T1,...
  'T2',                    T2,...
  'object',                C,...
  'image_coordinates',     P,...
  'off_resonance',         []);
tic
metadata = Scan(seq,api);
toc
Mxy = metadata.Mxy;
Mz = metadata.Mz;


%%
% Plot images
close all
for i=1:size(Mxy,3)
    figure(3)
    tiledlayout(1,2,'Padding','compact','TileSpacing','compact')
    nexttile
    imagesc(abs(Mxy(:,:,i))); caxis([-1 1])
    title('M_{xy}')
    axis equal off
    nexttile
    imagesc(Mz(:,:,i)); caxis([-1 1])
    title('M_{z}')
    axis equal off
    colormap gray
    sgtitle(sprintf('Time: %.0f msec',metadata.times(i)))
    drawnow
%     pause
end

%%
% Plot magnetization curves
figure(4)
subplot 221
plot(metadata.times,squeeze(abs(Mxy(25,25,:))),'Linewidth',2); hold on
plot(metadata.times,squeeze(Mz(25,25,:)),'Linewidth',2); hold off
title('T1=1500, T2=200')
legend('M_{xy}','M_z')
subplot 222
plot(metadata.times,squeeze(abs(Mxy(75,75,:))),'Linewidth',2); hold on
plot(metadata.times,squeeze(Mz(75,75,:)),'Linewidth',2); hold off
title('T1=800, T2=50')
legend('M_{xy}','M_z')
subplot 223
plot(metadata.times,squeeze(abs(Mxy(25,75,:))),'Linewidth',2); hold on
plot(metadata.times,squeeze(Mz(25,75,:)),'Linewidth',2); hold off
title('T1=1500, T2=200')
legend('M_{xy}','M_z')
subplot 224
plot(metadata.times,squeeze(abs(Mxy(75,25,:))),'Linewidth',2); hold on
plot(metadata.times,squeeze(Mz(75,25,:)),'Linewidth',2); hold off
title('T1=800, T2=50')
legend('M_{xy}','M_z')