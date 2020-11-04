clear; clc;

% Add functions to path
addpath(genpath('src/'))


%% IMAGE MODEL
% Gyromagnetic constant
gamma = 42.58;   % MHz/T

% Image size
Isz = [200 200];

% Image with two cylinders
I = zeros(Isz);

% Image domain
FOV = [0.35 0.35];
[X,Y] = meshgrid(linspace(-FOV(1)/2,FOV(1)/2,Isz(2)),...
                 linspace(-FOV(2)/2,FOV(2)/2,Isz(1)));
P = cat(3,X,Y);

% Add cylinders
R = sqrt(X.^2 + Y.^2);
C = R < 0.1;

% Off-resonance
df = (220*(Y>0) + 0*(Y<=0))/(2*pi);

% figure(1)
% imagesc(C)

%% Sequence definition
% Directions for gradients
dir1 = [1];
dir2 = [2];

% Create objects for prepulse
G = 15;
dT = 0.05;
tip = deg2rad(90);
for nsa = [1 2]

    if nsa == 1
        RF1 = RF(struct('angle',tip,'phase',0,'ref_obj','ref'));
        GR1 = GR(struct('dir',dir1,'amp',G,'dur',dT,'ref_obj',RF1));
        RF2 = RF(struct('angle',tip,'phase',0,'ref_obj',GR1));
        GR2 = GR(struct('dir',1,'ref_obj',RF2,'crusher',true));
        RF3 = [];
        GR3 = [];
        RF4 = [];
    elseif nsa == 2
        RF1 = RF(struct('angle',tip,'phase',0,'ref_obj','ref'));
        GR1 = GR(struct('dir',dir1,'amp',G,'dur',dT,'ref_obj',RF1));
        RF2 = RF(struct('angle',tip,'phase',deg2rad(180),'ref_obj',GR1));
        GR2 = GR(struct('dir',1,'ref_obj',RF2,'crusher',true));
        RF3 = [];
        GR3 = [];
        RF4 = [];
    end
    
    % Prepulse object
    prep = Preparation(struct('RF1',RF1,'GR1',GR1,'RF2',RF2,'GR2',GR2,'RF3',RF3,'GR3',GR3,'RF4',RF4));

    % Create objects for acquisition
    aRF1 = RF(struct('angle',15*pi/180,'phase',0,'ref_obj','ref'));
    aGR1 = GR(struct('dir',dir1,'amp',0,'dur',dT,'ref_obj',aRF1));

    % Acquisition object
    acq = Acquisition(struct('RF1',aRF1,'GR1',aGR1,'prep_delay',prep.objects{end}.time+10,'TR',50,'nb_frames',16));

    % Sequence object
    seq = Sequence(struct('preparation',prep,'acquisition',acq));

    %% Simulation
    api = struct(...
      'homogenize_times',      false,...
      'gyromagnetic_constant', gamma,...
      'M0',                    1.0,...
      'T1',                    850,...
      'T2',                    50,...
      'object',                C,...
      'image_coordinates',     P,...
      'off_resonance',         df);
    tic
    metadata = Scan(seq,api);
    toc

    % Reshape results
    if nsa == 1
        Mr1 = metadata.Mxy;
    elseif nsa == 2
        Mr2 = metadata.Mxy;
    end

end

% Get CSPAMM images
M1 = Mr1 - Mr2;
M2 = Mr1 + Mr2;

% Plot images
im = 0;
for i=1:numel(metadata.times)
    if mod(i,1)==0
      figure(3)
      tiledlayout(3,2,'Padding','compact','TileSpacing','compact')
      nexttile
      imagesc(abs(M1(:,:,i+1)));
      title('M_{xy}')
      axis equal off
      nexttile
      imagesc(abs(M2(:,:,i+1)));
      title('M_{xy}')
      axis equal off
      nexttile
      imagesc(abs(itok(M1(:,:,i+1)))); caxis([0 50])
      title('M_{xy}')
      axis equal off
      nexttile
      imagesc(abs(itok(M2(:,:,i+1)))); caxis([0 50])
      title('M_{xy}')
      axis equal off
      nexttile
      plot(real(diag(M1(:,:,i+1)))); hold on
      plot(imag(diag(M1(:,:,i+1)))); hold off
      legend('Real','Imag')
      nexttile
      plot(real(diag(M2(:,:,i+1)))); hold on
      plot(imag(diag(M2(:,:,i+1)))); hold off
      legend('Real','Imag')
      sgtitle(sprintf('Time: %.0f msec',metadata.times(i)))
      drawnow
    end  
end