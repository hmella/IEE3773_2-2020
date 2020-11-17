function metadata = EPIScan(varargin)

    % Default arguments
    defapi = struct(...
      'Mxy',                   false,...
      'gyromagnetic_constant', 42.58,...  % MHz/T
      'T1',                    850,...    % msec
      'T2',                    50,...     % msec
      'object',                [],...
      'image_coordinates',     [],...
      'show',                  false,...
      'off_resonance',         [],...     % Hz
      'delta_B0',              []);       % mT

    % Parse inputs
    api = parseinputs(defapi,[],varargin{:});

    % Image size
    Isz = size(api.object,[1 2]);

    % T1 and T2 maps
    T1 = api.T1;
    T2 = api.T2;
    
    % Gyromagnetic constant
    gamma = api.gyromagnetic_constant;   % Hz/T
    
    % Object positions
    P = api.image_coordinates;

    % Proton density
    PD = double(api.object);
    
    % FOV
    FOV = [P(1,Isz(2),1)-P(1,1,1), P(Isz(1),1,2)-P(1,1,2)];

    % Pixel size
    pxsz = [P(1,2,1)-P(1,1,1), P(2,1,2)-P(1,1,2)];
    

    %% Gradients calculation
    % Kspace bandwidth and spacing
    BW = 1.0./pxsz;
    dk = 1.0./FOV;

    % Blip gradient
    blip_dur = 0.1;  
    blip_str = (dk(2)*2*pi)/(gamma*blip_dur);
    blip_dur_ini = 1;  
    blip_str_ini = -(BW(2)*pi)/(gamma*blip_dur_ini);

    % Readout gradient
    ro_dur = 0.01; 
    ro_str = (dk(1)*2*pi)/(gamma*ro_dur);
    ro_dur_ini = 1; 
    ro_str_ini = -(BW(1)*pi)/(gamma*ro_dur_ini);    

  
    %% Start simulation
    % Solution vector
    M = zeros([3 1 prod(Isz)]);
    M(1,:,:) = real(reshape(api.Mxy,[1 1 prod(Isz)]));
    M(2,:,:) = imag(reshape(api.Mxy,[1 1 prod(Isz)]));

    % Kspace and trajectory
    K = zeros([Isz(1) Isz(2)]);
    k_traj = zeros([1 2]);
    k_traj_c = 1;

    % Solve the Bloch's equations
    kx_samples = Isz(1);
    ky_lines   = Isz(2);
    for ky=1:ky_lines
      
       %% Gradients strenghts and dur
        % Readout gradient (jump between frequency samples)
        dur_ro = ro_dur;
        % str_ro = (-1)^(ky-1)*ro_str;
        str_ro = ro_str;
        
        % Blip gradients (jump between lines in phase dir)
        if ky == 1
            dur_blip = max([blip_dur_ini,ro_dur_ini]);
            str_blip = sqrt((ro_str_ini*ro_dur_ini).^2 + ...
                            (blip_str_ini*blip_dur_ini).^2)/ ...
                             dur_blip;
            dir = pi + atan(blip_str_ini*blip_dur_ini/(ro_str_ini*ro_dur_ini));
        else
            % dur_blip = blip_dur;
            % str_blip = blip_str;
            % dir = pi/2;
            dur_blip = max([blip_dur,ro_dur_ini]);
            str_blip = sqrt((2*ro_str_ini*ro_dur_ini).^2 + ...
                            (blip_str*blip_dur).^2)/ ...
                             dur_blip;
            dir = pi + atan(blip_str*blip_dur/(2*ro_str_ini*ro_dur_ini));
        end
            
        
        %% Blip       
        % Relaxation matrices
%         [A_relax, B_relax] = Relaxation(dur_blip,T1,T2);

        % Rotation due to phase and/or frequency gradients
        theta_gr = (P(:,:,1)*cos(dir) + P(:,:,2)*sin(dir))*(gamma*str_blip*dur_blip);
        R_z_gr = ZRotation(theta_gr);

        % Rotation due to off-resonance and inhomogeneity effects
        theta_i = 0;
        if ~isempty(api.off_resonance)
            theta_i = theta_i + ...
                    2*pi*api.off_resonance*(1.0e-03*dur_blip);
        end
        if ~isempty(api.delta_B0)
            theta_i = theta_i + ...
                    gamma*delta_B0*dur_blip;
        end
        R_z_in = ZRotation(theta_i);

        % Get magnetization after blip
%         M(:,:,:) =  mtimesx(R_z_gr, mtimesx(R_z_in, mtimesx(A_relax, M(:,:,:)))) + B_relax;
        M(:,:,:) = mtimesx(R_z_gr, mtimesx(R_z_in, M(:,:,:)));% + B_relax;

        % Update trajectory
        k_traj_c = k_traj_c + 1;
        k_traj(k_traj_c,1) = k_traj(k_traj_c-1,1) + gamma/(2*pi)*cos(dir)*str_blip*dur_blip;
        k_traj(k_traj_c,2) = k_traj(k_traj_c-1,2) + gamma/(2*pi)*sin(dir)*str_blip*dur_blip;        
      

        %% Readout      
        % Relaxation matrices
%         [A_relax, B_relax] = Relaxation(dur_ro,T1,T2);        
        
        % Samples in frequency direction
        for kx=1:kx_samples
          
            % Change direction
            dir = 0;

            % Signal generation
            Mr = reshape(permute(M,[3 2 1]),[Isz 3]);
            Mr = Mr(:,:,1) + 1j*Mr(:,:,2);
            tmp = exp(-1i*2*pi*(P(:,:,1)*k_traj(end,2)+P(:,:,2)*k_traj(end,1)));
            K(ky,kx) = api.Mxy(:)'*tmp(:);
%             K(ky,kx) = sum(Mr(:));
            if kx==kx_samples
                break
            end
          
            % Rotation due to phase and/or frequency gradients
            theta_gr = (P(:,:,1)*cos(dir) + P(:,:,2)*sin(dir))*(gamma*str_ro*dur_ro);
            R_z_gr = ZRotation(theta_gr);

            % Rotation due to off-resonance and inhomogeneity effects
            theta_i = 0;
            if ~isempty(api.off_resonance)
                theta_i = theta_i + ...
                        2*pi*api.off_resonance*(1.0e-03*dur_ro);
            end
            if ~isempty(api.delta_B0)
                theta_i = theta_i + ...
                        gamma*delta_B0*dur_ro;
            end
            R_z_in = ZRotation(theta_i);

            % Get magnetization after readout
%             M(:,:,:) = mtimesx(R_z_gr, mtimesx(R_z_in, mtimesx(A_relax, M(:,:,:)))) + B_relax;
            M(:,:,:) = mtimesx(R_z_gr, mtimesx(R_z_in, M(:,:,:)));% + B_relax;

            % Update trajectory
            k_traj_c = k_traj_c + 1;
            k_traj(k_traj_c,1) = k_traj(k_traj_c-1,1) + gamma/(2*pi)*cos(dir)*str_ro*dur_ro;
            k_traj(k_traj_c,2) = k_traj(k_traj_c-1,2) + gamma/(2*pi)*sin(dir)*str_ro*dur_ro;           
            
        end
        
        figure(1)
        subplot 221
        imagesc(abs(K)); set(gca,'YDir','normal')
        subplot 222
        plot(k_traj(:,1),k_traj(:,2),'LineWidth',2)
        axis([-0.6*BW(1) 0.6*BW(1) -0.6*BW(2) 0.6*BW(2)])
        subplot 223
        imagesc(abs(ktoi(K))); set(gca,'YDir','normal')
        subplot 224
        imagesc(angle(ktoi(K))); set(gca,'YDir','normal')
        drawnow        
        
    end
    
    % Prepare outputs
    metadata = struct(...
      'kspace',     K,...
      'trajectory', k_traj);
      
  
end